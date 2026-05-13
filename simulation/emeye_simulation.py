#!/usr/bin/env python3
"""
EM Eye Power-Line Side-Channel Simulation
==========================================
End-to-end simulation of the EM Eye attack pipeline using synthetic data,
mimicking what would run on real LDSDR + ERA-4SM+ x2 LNA hardware.

Pipeline:
    1. SOURCE   : simulate camera MIPI CSI-2 image transmission
    2. FRONTEND : simulate EM leakage capture via broadband CT + LNA + SDR
    3. WIRELESS : simulate IQ data transport (placeholder for WiFi / Ethernet)
    4. RECEIVE  : capture IQ stream on host PC
    5. RECONS   : EM Eye amplitude demod + Tf/Tr autocorrelation + 2D reshape

Reference:
    Long, Yan, et al. "EM Eye: Characterizing Electromagnetic Side-channel
    Eavesdropping on Embedded Cameras." NDSS 2024.

Hardware target (this simulation models):
    - LDSDR 7010 (AD9363, 70 MHz - 6 GHz, 2T2R, Gigabit Ethernet)
    - Custom ERA-4SM+ x2 LNA (BYO, measured +28 dB @ 100 MHz)
    - Wideband CT (Phase 0: Tekbox TBCP2-1000 or equivalent)

Usage:
    python emeye_simulation.py
    python emeye_simulation.py --image input.png
    python emeye_simulation.py --no-display
"""

import argparse
import os
import time
from pathlib import Path

import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw


# ============================================================
# Configuration (matching EM Eye paper + our hardware plan)
# ============================================================
CONFIG = {
    'frame_rate_hz': 30.0,        # camera fps (RPi V1)
    'sample_rate_msps': 8.0,      # SDR sample rate (paper: fs=8 MHz)
    'carrier_mhz': 204.0,         # byte clock x 4 (RPi V1 main target)
    'byte_clock_mhz': 51.0,       # MIPI CSI-2 byte rate (RPi V1)
    'img_height': 80,             # H_EM in paper terms
    'img_width': 160,             # W_EM in paper terms
    'n_frames': 2,                # simulate 2 consecutive frames
    'noise_std': 0.06,            # complex Gaussian noise std
    'active_ratio': 0.92,         # active data / total frame time
    'lna_gain_db': 28,            # measured ERA-4SM+ x2 cascade gain
}


def generate_test_image(W, H):
    """Generate synthetic test image with recognizable patterns."""
    img = np.zeros((H, W), dtype=np.uint8)

    # Horizontal gradient (left dark -> right bright)
    grad = np.tile(np.linspace(40, 200, W), (H, 1)).astype(np.uint8)
    img = grad.copy()

    # Concentric squares
    cx, cy = W // 2, H // 2
    for radius in range(min(W, H) // 3, 5, -8):
        x_low, x_high = max(0, cx - radius), min(W, cx + radius)
        y_low, y_high = max(0, cy - radius), min(H, cy + radius)
        val = (50 + (radius * 7)) % 256
        img[y_low:y_high, x_low:x_high] = val

    # Bright dots (high-contrast features)
    np.random.seed(2026)
    for _ in range(8):
        x = np.random.randint(2, W - 3)
        y = np.random.randint(2, H - 3)
        img[y:y + 3, x:x + 3] = 250

    # Text label
    try:
        pil_img = Image.fromarray(img)
        draw = ImageDraw.Draw(pil_img)
        draw.text((5, H - 12), "EM Eye Sim", fill=255)
        img = np.array(pil_img)
    except Exception:
        pass

    return img


def simulate_em_leakage(image, cfg):
    """
    Simulate EM leakage IQ stream from camera image transmission.

    Models:
    - MIPI CSI-2 row-by-row, pixel-by-pixel serial transmission
    - EM emission at byte-clock harmonic (carrier_mhz)
    - SDR down-conversion to baseband IQ (so we generate baseband directly)
    - Per-pixel amplitude proportional to pixel value (paper Eq. 2)
    - Random phase per pixel (simulates RF propagation phase)
    - AWGN representing thermal + interference noise
    """
    fs = cfg['sample_rate_msps'] * 1e6
    Tf = 1.0 / cfg['frame_rate_hz']
    H, W = image.shape
    samples_per_frame = int(fs * Tf)
    n_frames = cfg['n_frames']

    samples_per_row = samples_per_frame // H
    active_samples_per_row = int(samples_per_row * cfg['active_ratio'])
    samples_per_pixel = max(1, active_samples_per_row // W)

    total_samples = samples_per_frame * n_frames
    iq = np.zeros(total_samples, dtype=np.complex64)

    np.random.seed(42)

    for f in range(n_frames):
        frame_offset = f * samples_per_frame
        for row in range(H):
            row_offset = frame_offset + row * samples_per_row
            for col in range(W):
                px_start = row_offset + col * samples_per_pixel
                px_end = px_start + samples_per_pixel
                if px_end > total_samples:
                    break
                pix_val = image[row, col] / 255.0  # normalize 0-1
                phase = 2 * np.pi * np.random.rand()
                iq[px_start:px_end] = pix_val * np.exp(1j * phase)

    # Additive white Gaussian noise (complex)
    noise = cfg['noise_std'] * (
        np.random.randn(total_samples) + 1j * np.random.randn(total_samples)
    )
    iq += noise

    # Apply frontend gain (LNA cascade) - just scales amplitude
    gain_linear = 10 ** (cfg['lna_gain_db'] / 20.0)
    iq *= gain_linear

    return iq, samples_per_frame


def simulate_wireless_transmission(iq, label='LDSDR Gigabit Ethernet'):
    """Simulate transmitting IQ data wirelessly to host PC.

    Real system: TCP/UDP socket over WiFi 6 or Gigabit Ethernet from
    LDSDR to laptop. Here we just compute the bandwidth needed.
    """
    n_samples = len(iq)
    # complex64 = 8 bytes/sample (typical SDR uses 12-bit packed to 16-bit = 4 bytes)
    bytes_per_sample = 4
    total_bytes = n_samples * bytes_per_sample
    bw_mbps = total_bytes * 8 / 1e6
    duration_s = n_samples / (CONFIG['sample_rate_msps'] * 1e6)

    print(f"  Transport: {label}")
    print(f"  Samples  : {n_samples:,}")
    print(f"  Volume   : {total_bytes / 1e6:.2f} MB")
    print(f"  Duration : {duration_s * 1000:.1f} ms")
    print(f"  Required : {bw_mbps:.1f} Mbps (Gigabit Ethernet has 800+ Mbps headroom)")

    return iq.copy()


def estimate_tf(amplitude, fs, expected_fps=30):
    """Estimate frame period Tf using normalized autocorrelation.

    Uses coarse-then-fine search for efficiency. Normalizes by overlap
    count so that bias toward shorter lags (more overlapping samples)
    is removed.
    """
    expected_lag = int(fs / expected_fps)
    lag_min = int(expected_lag * 0.90)
    lag_max = int(expected_lag * 1.10)

    # Coarse search: ~50 lag points
    coarse_step = max(1, (lag_max - lag_min) // 50)
    coarse_lags = np.arange(lag_min, lag_max, coarse_step)
    coarse_vals = np.zeros(len(coarse_lags))

    # Demean amplitude for cleaner correlation
    amp_dm = amplitude - amplitude.mean()

    for i, lag in enumerate(coarse_lags):
        if lag >= len(amp_dm):
            continue
        x1 = amp_dm[:len(amp_dm) - lag]
        x2 = amp_dm[lag:]
        # Normalize by number of overlapping samples (key fix)
        coarse_vals[i] = np.mean(x1 * x2)

    peak_coarse_idx = np.argmax(coarse_vals)
    peak_coarse_lag = coarse_lags[peak_coarse_idx]

    # Fine search around peak (within +/- coarse_step)
    fine_lag_min = max(lag_min, peak_coarse_lag - coarse_step)
    fine_lag_max = min(lag_max, peak_coarse_lag + coarse_step + 1)
    fine_lags = np.arange(fine_lag_min, fine_lag_max)
    fine_vals = np.zeros(len(fine_lags))

    for i, lag in enumerate(fine_lags):
        if lag >= len(amp_dm) or lag <= 0:
            continue
        x1 = amp_dm[:len(amp_dm) - lag]
        x2 = amp_dm[lag:]
        fine_vals[i] = np.mean(x1 * x2)

    peak_fine_idx = np.argmax(fine_vals)
    Tf_samples = fine_lags[peak_fine_idx]

    return Tf_samples, coarse_vals, coarse_lags, fine_vals, fine_lags


def reconstruct_image(iq, cfg):
    """
    Apply EM Eye reconstruction pipeline (matching paper Eq. 2).

    Steps:
        1. Amplitude demodulation: |I + jQ|
        2. Estimate Tf via autocorrelation
        3. Extract one frame
        4. Estimate samples_per_row = Tf / H_expected
        5. Reshape 1D -> 2D
        6. Downsample columns to match expected W
        7. Histogram normalization
    """
    fs = cfg['sample_rate_msps'] * 1e6

    # 1. Amplitude demodulation
    amplitude = np.abs(iq)

    # 2. Estimate Tf
    Tf_samples, _, _, _, _ = estimate_tf(
        amplitude, fs, cfg['frame_rate_hz']
    )
    Tf_ms = Tf_samples / fs * 1000
    print(f"  Estimated Tf  = {Tf_ms:.3f} ms  "
          f"(expected {1000 / cfg['frame_rate_hz']:.3f} ms)")

    # 3. Take one frame
    frame_data = amplitude[:Tf_samples]

    # 4. Compute Tr based on expected H
    H_expected = cfg['img_height']
    W_expected = cfg['img_width']
    Tr_samples = Tf_samples // H_expected
    Tr_us = Tr_samples / fs * 1e6
    print(f"  Estimated Tr  = {Tr_us:.2f} us "
          f"(assuming H={H_expected} rows)")
    print(f"  Samples/pixel = {Tr_samples // W_expected} (W={W_expected})")

    # 5. Reshape to 2D
    truncated = frame_data[:Tr_samples * H_expected]
    image_2d = truncated.reshape(H_expected, Tr_samples)

    # 6. Downsample to expected width by averaging
    active_samples = int(Tr_samples * cfg['active_ratio'])
    if active_samples >= W_expected:
        bin_size = active_samples // W_expected
        active_region = image_2d[:, :W_expected * bin_size]
        image_2d = active_region.reshape(
            H_expected, W_expected, bin_size
        ).mean(axis=2)
    else:
        image_2d = image_2d[:, :W_expected]

    # 7. Histogram normalization (full range stretch)
    img_min, img_max = image_2d.min(), image_2d.max()
    if img_max > img_min:
        image_2d = (image_2d - img_min) / (img_max - img_min) * 255

    return image_2d.astype(np.uint8), Tf_ms, Tr_us


def compute_metrics(original, reconstructed):
    """Compute SSIM, correlation, MSE between original and reconstructed."""
    orig = original.astype(np.float64)
    recon = reconstructed.astype(np.float64)

    # Mean Squared Error
    mse = np.mean((orig - recon) ** 2)

    # Correlation coefficient
    orig_flat = orig.flatten() - orig.mean()
    recon_flat = recon.flatten() - recon.mean()
    if orig_flat.std() > 0 and recon_flat.std() > 0:
        corr = np.mean(orig_flat * recon_flat) / (orig_flat.std() * recon_flat.std())
    else:
        corr = 0.0

    # Simple SSIM proxy (ignores luminance/contrast structure terms separately)
    mu_x = orig.mean()
    mu_y = recon.mean()
    sigma_x2 = orig.var()
    sigma_y2 = recon.var()
    sigma_xy = np.mean((orig - mu_x) * (recon - mu_y))
    c1 = (0.01 * 255) ** 2
    c2 = (0.03 * 255) ** 2
    ssim = ((2 * mu_x * mu_y + c1) * (2 * sigma_xy + c2)) / \
        ((mu_x ** 2 + mu_y ** 2 + c1) * (sigma_x2 + sigma_y2 + c2))

    return {'mse': mse, 'corr': corr, 'ssim': ssim}


def visualize_pipeline(original, iq, reconstructed, metrics, cfg, save_path):
    """Generate end-to-end pipeline visualization."""
    fs = cfg['sample_rate_msps'] * 1e6
    samples_per_frame = int(fs / cfg['frame_rate_hz'])

    fig, axes = plt.subplots(2, 2, figsize=(14, 9))

    # (a) Original image
    axes[0, 0].imshow(original, cmap='gray', vmin=0, vmax=255)
    axes[0, 0].set_title(
        f'(a) Original camera image\n'
        f'{original.shape[1]} x {original.shape[0]} grayscale',
        fontsize=11
    )
    axes[0, 0].axis('off')

    # (b) IQ amplitude (1 frame)
    amp_1f = np.abs(iq[:samples_per_frame])
    t_ms = np.arange(len(amp_1f)) / fs * 1000
    axes[0, 1].plot(t_ms, amp_1f, linewidth=0.3, color='steelblue')
    axes[0, 1].set_title(
        f'(b) Received IQ amplitude (1 frame)\n'
        f'fc = {cfg["carrier_mhz"]} MHz, fs = {cfg["sample_rate_msps"]} MSPS',
        fontsize=11
    )
    axes[0, 1].set_xlabel('Time (ms)')
    axes[0, 1].set_ylabel('|I + jQ|')
    axes[0, 1].grid(True, alpha=0.3)

    # (c) Autocorrelation for Tf (use the corrected normalized version)
    amp = np.abs(iq)
    _, coarse_vals, coarse_lags, _, _ = estimate_tf(
        amp, fs, cfg['frame_rate_hz']
    )
    auto_norm = coarse_vals / np.max(np.abs(coarse_vals))
    lag_ms = coarse_lags / fs * 1000
    peak_lag_ms = coarse_lags[np.argmax(coarse_vals)] / fs * 1000

    axes[1, 0].plot(lag_ms, auto_norm, linewidth=1, color='darkgreen', marker='.', markersize=4)
    axes[1, 0].axvline(
        peak_lag_ms, color='red', linestyle='--',
        label=f'Peak: {peak_lag_ms:.2f} ms'
    )
    axes[1, 0].axvline(
        1000 / cfg['frame_rate_hz'], color='gray', linestyle=':',
        label=f'Expected: {1000/cfg["frame_rate_hz"]:.2f} ms'
    )
    axes[1, 0].set_title('(c) Tf estimation via autocorrelation', fontsize=11)
    axes[1, 0].set_xlabel('Lag (ms)')
    axes[1, 0].set_ylabel('Normalized autocorrelation')
    axes[1, 0].legend(loc='best', fontsize=9)
    axes[1, 0].grid(True, alpha=0.3)

    # (d) Reconstructed
    axes[1, 1].imshow(reconstructed, cmap='gray', vmin=0, vmax=255)
    axes[1, 1].set_title(
        f'(d) Reconstructed (EM Eye pipeline)\n'
        f'SSIM={metrics["ssim"]:.3f}, Corr={metrics["corr"]:.3f}, '
        f'MSE={metrics["mse"]:.0f}',
        fontsize=11
    )
    axes[1, 1].axis('off')

    plt.suptitle(
        'EM Eye Power-Line Side-Channel Simulation - End-to-End Pipeline',
        fontsize=13, fontweight='bold'
    )
    plt.tight_layout()
    plt.savefig(save_path, dpi=120, bbox_inches='tight')
    print(f"\n  Visualization saved: {save_path}")
    return fig


def main():
    parser = argparse.ArgumentParser(
        description='EM Eye Power-Line Side-Channel Simulation'
    )
    parser.add_argument('--image', type=str, default=None,
                        help='Input image (PNG/JPG); auto-generates if omitted')
    parser.add_argument('--output', type=str, default='output/reconstructed.png',
                        help='Reconstructed image output path')
    parser.add_argument('--vis', type=str, default='output/simulation_result.png',
                        help='4-panel visualization output path')
    parser.add_argument('--no-display', action='store_true',
                        help='Skip matplotlib show() (batch mode)')
    parser.add_argument('--seed', type=int, default=42,
                        help='Random seed (default 42)')
    args = parser.parse_args()

    np.random.seed(args.seed)
    cfg = CONFIG.copy()

    # Ensure output directory exists
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    Path(args.vis).parent.mkdir(parents=True, exist_ok=True)

    print("=" * 72)
    print("  EM Eye Power-Line Side-Channel Attack Simulation")
    print("  Based on Long et al., NDSS 2024")
    print("=" * 72)
    print()
    print(f"Hardware target: LDSDR 7010 + ERA-4SM+ x2 LNA + broadband CT")
    print(f"  Carrier        : {cfg['carrier_mhz']} MHz "
          f"(RPi V1 byte clock x 4)")
    print(f"  Sample rate    : {cfg['sample_rate_msps']} MSPS")
    print(f"  Frame rate     : {cfg['frame_rate_hz']} Hz")
    print(f"  Image dims     : {cfg['img_width']} x {cfg['img_height']}")
    print(f"  N frames       : {cfg['n_frames']}")
    print(f"  Frontend gain  : +{cfg['lna_gain_db']} dB "
          f"(measured ERA-4SM+ x2)")

    t0 = time.time()

    # ---- Step 1: Source image ----
    print("\n[1/5] SOURCE  ----------------------------------------------------")
    if args.image and os.path.exists(args.image):
        img = np.array(
            Image.open(args.image).convert('L').resize(
                (cfg['img_width'], cfg['img_height'])
            )
        )
        print(f"  Loaded user image: {args.image}")
    else:
        img = generate_test_image(cfg['img_width'], cfg['img_height'])
        print(f"  Generated synthetic test image: shape={img.shape}")

    src_path = Path(args.output).parent / 'source_image.png'
    Image.fromarray(img).save(src_path)
    print(f"  Source saved: {src_path}")

    # ---- Step 2: Frontend signal acquisition ----
    print("\n[2/5] FRONTEND  --------------------------------------------------")
    print("  Simulating CT + LNA + AD9363 mixer + ADC ...")
    t_start = time.time()
    iq, samples_per_frame = simulate_em_leakage(img, cfg)
    t_gen = time.time() - t_start
    print(f"  Generation time: {t_gen:.2f}s")
    print(f"  Samples generated: {len(iq):,}")
    print(f"  Duration: {len(iq) / (cfg['sample_rate_msps'] * 1e6) * 1000:.1f} ms")
    print(f"  Peak |IQ|: {np.abs(iq).max():.2f}")
    print(f"  Mean |IQ|: {np.abs(iq).mean():.2f}")

    # ---- Step 3: Wireless transmission ----
    print("\n[3/5] WIRELESS TRANSPORT  ----------------------------------------")
    received_iq = simulate_wireless_transmission(
        iq, label='LDSDR Gigabit Ethernet -> Host PC'
    )

    # ---- Step 4: Reconstruction ----
    print("\n[4/5] RECONSTRUCTION  --------------------------------------------")
    print("  Applying EM Eye amplitude demodulation pipeline ...")
    t_start = time.time()
    reconstructed, Tf_ms, Tr_us = reconstruct_image(received_iq, cfg)
    t_recon = time.time() - t_start
    print(f"  Reconstruction time: {t_recon:.2f}s")
    print(f"  Output shape: {reconstructed.shape}")

    # ---- Step 5: Output + metrics ----
    print("\n[5/5] OUTPUT  ----------------------------------------------------")
    metrics = compute_metrics(img, reconstructed)
    print(f"  SSIM        : {metrics['ssim']:.4f}")
    print(f"  Correlation : {metrics['corr']:.4f}")
    print(f"  MSE         : {metrics['mse']:.2f}")

    Image.fromarray(reconstructed).save(args.output)
    print(f"  Reconstructed saved: {args.output}")

    # ---- Visualization ----
    fig = visualize_pipeline(img, received_iq, reconstructed, metrics, cfg, args.vis)

    elapsed = time.time() - t0
    print(f"\nTotal runtime: {elapsed:.1f}s")

    print("\n" + "=" * 72)
    print("  Simulation complete!")
    print("=" * 72)
    print("\nNext steps:")
    print("  - On real hardware, replace simulate_em_leakage() with LDSDR")
    print("    IQ capture via libiio / GNURadio sink")
    print("  - Replace simulate_wireless_transmission() with TCP socket from")
    print("    LDSDR PS to host PC over Gigabit Ethernet")
    print("  - The reconstruct_image() pipeline is hardware-agnostic and runs")
    print("    on host PC unchanged")
    print()

    if not args.no_display:
        try:
            plt.show()
        except Exception as e:
            print(f"  Note: cannot display interactively ({e})")


if __name__ == '__main__':
    main()
