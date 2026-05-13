#!/usr/bin/env python3
"""
HDMI TEMPEST Side-Channel Simulation (PlutoSDR / LDSDR)
========================================================

Adaptation of EM Eye attack to HDMI cables. Same algorithm pipeline:
amplitude demodulation + frame sync + 2D reshape.

Key differences from camera EM Eye:
  - Target carrier: TMDS pixel clock harmonics (148.5 MHz for 1080p60)
  - Frame rate: 60 Hz (vs 30 Hz for cameras)
  - Explicit H_sync / V_sync (vs implicit blanking)
  - Higher pixel rate -> coarser effective resolution at 8 MSPS

Hardware target:
  - PlutoSDR / LDSDR 7010 + ERA-4SM+ x2 LNA + wideband near-field H probe
  - Probe placed on/near HDMI cable
  - Pluto tuned to 148.5 MHz (1st pixel-clock harmonic) or higher harmonics

References:
  - EM Eye (Long et al., NDSS 2024) - algorithm pipeline
  - Kuhn 2002/2013 - TEMPEST CRT/LCD background
  - de Meulemeester et al. 2020 - 80m UHD eavesdropping

Usage:
    python hdmi_simulation.py
    python hdmi_simulation.py --image input.png
"""

import argparse
import os
import time
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw


# ============================================================
# Configuration - matched to HDMI 1080p60 (scaled down for sim speed)
# ============================================================
# Real HDMI 1080p60:
#   - Pixel clock 148.5 MHz
#   - Active 1920x1080, total 2200x1125 (with blanking)
#   - Frame rate 60 Hz, line rate 67.5 kHz
#
# For simulation, we use SCALED dimensions to keep runtime manageable
# while preserving the key timing relationships:
CONFIG = {
    'frame_rate_hz': 60.0,        # HDMI 1080p60 native
    'sample_rate_msps': 8.0,      # Pluto/LDSDR SDR sample rate
    'carrier_mhz': 148.5,         # HDMI 1080p60 pixel clock 1st harmonic
    'img_height': 90,             # scaled from 1080 (12x reduction)
    'img_width': 160,             # scaled from 1920 (12x reduction)
    'h_blank_ratio': 0.13,        # H_blank: 280/2200 ~12.7% of line
    'v_blank_ratio': 0.04,        # V_blank: 45/1125 ~4% of frame
    'n_frames': 2,
    'noise_std': 0.06,
    'lna_gain_db': 28,
}


def generate_hdmi_test_image(W, H):
    """Generate HD-aspect test image with TEMPEST-relevant features."""
    img = np.zeros((H, W), dtype=np.uint8)

    # Background: dark
    img[:, :] = 30

    # Horizontal bars (typical for HDMI quality test)
    bar_h = H // 8
    for i in range(8):
        intensity = int(30 + i * 28)
        img[i*bar_h:(i+1)*bar_h, :W//2] = intensity

    # Bright vertical lines on right side (test pattern)
    for x in range(W//2, W, 8):
        img[:, x:x+2] = 240

    # Central rectangle (typical 'desktop window')
    cx, cy = W // 2, H // 2
    box_w, box_h = W // 4, H // 4
    img[cy-box_h//2:cy+box_h//2, cx-box_w//2:cx+box_w//2] = 200

    # Text overlay (typical TEMPEST target - readability test)
    try:
        pil_img = Image.fromarray(img)
        draw = ImageDraw.Draw(pil_img)
        draw.text((10, 8), "HDMI TEMPEST", fill=255)
        draw.text((10, H-15), "Pluto SDR @ 148.5MHz", fill=200)
        img = np.array(pil_img)
    except Exception:
        pass

    return img


def simulate_hdmi_leakage(image, cfg):
    """Simulate HDMI TMDS EM leakage IQ stream.

    Models:
    - Pixel-by-pixel, line-by-line transmission (like MIPI but with explicit blanking)
    - H_blank between lines (~13% of line time, no signal)
    - V_blank between frames (~4% of frame time, no signal)
    - EM emission at pixel-clock harmonic (down-converted to baseband)
    - Per-pixel amplitude proportional to pixel value
    - Random phase per pixel (RF propagation)
    - AWGN noise
    """
    fs = cfg['sample_rate_msps'] * 1e6
    Tf = 1.0 / cfg['frame_rate_hz']  # 16.67 ms at 60 fps
    H, W = image.shape
    samples_per_frame = int(fs * Tf)
    n_frames = cfg['n_frames']

    h_blank = cfg['h_blank_ratio']  # 13% of line is blanking
    v_blank = cfg['v_blank_ratio']  # 4% of frame is V_blank

    # Frame has active rows + V_blank rows
    active_rows = H
    total_rows_with_vblank = int(H / (1 - v_blank))

    # Each line: active pixels + H_blank
    samples_per_line = samples_per_frame // total_rows_with_vblank
    active_samples_per_line = int(samples_per_line * (1 - h_blank))
    samples_per_pixel = max(1, active_samples_per_line // W)

    total_samples = samples_per_frame * n_frames
    iq = np.zeros(total_samples, dtype=np.complex64)

    np.random.seed(42)

    for f in range(n_frames):
        frame_offset = f * samples_per_frame
        for row in range(H):
            line_offset = frame_offset + row * samples_per_line
            for col in range(W):
                px_start = line_offset + col * samples_per_pixel
                px_end = px_start + samples_per_pixel
                if px_end > total_samples:
                    break
                pix_val = image[row, col] / 255.0
                phase = 2 * np.pi * np.random.rand()
                iq[px_start:px_end] = pix_val * np.exp(1j * phase)
            # H_blank: leave at noise level (samples between active end and next line)

    # AWGN
    noise = cfg['noise_std'] * (
        np.random.randn(total_samples) + 1j * np.random.randn(total_samples)
    )
    iq += noise

    # LNA gain
    gain = 10 ** (cfg['lna_gain_db'] / 20.0)
    iq *= gain

    return iq, samples_per_frame


def estimate_tf(amplitude, fs, expected_fps=60):
    """Normalized autocorrelation Tf estimation (same as EM Eye)."""
    expected_lag = int(fs / expected_fps)
    lag_min = int(expected_lag * 0.90)
    lag_max = int(expected_lag * 1.10)

    coarse_step = max(1, (lag_max - lag_min) // 50)
    coarse_lags = np.arange(lag_min, lag_max, coarse_step)
    coarse_vals = np.zeros(len(coarse_lags))

    amp_dm = amplitude - amplitude.mean()

    for i, lag in enumerate(coarse_lags):
        if lag >= len(amp_dm):
            continue
        x1 = amp_dm[:len(amp_dm) - lag]
        x2 = amp_dm[lag:]
        coarse_vals[i] = np.mean(x1 * x2)

    peak_coarse_idx = np.argmax(coarse_vals)
    peak_coarse_lag = coarse_lags[peak_coarse_idx]

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

    Tf_samples = fine_lags[np.argmax(fine_vals)]
    return Tf_samples, coarse_vals, coarse_lags


def reconstruct_hdmi(iq, cfg):
    """Apply EM Eye-style reconstruction adapted for HDMI."""
    fs = cfg['sample_rate_msps'] * 1e6

    amplitude = np.abs(iq)

    Tf_samples, _, _ = estimate_tf(amplitude, fs, cfg['frame_rate_hz'])
    Tf_ms = Tf_samples / fs * 1000
    print(f"  Estimated Tf  = {Tf_ms:.3f} ms (expected {1000/cfg['frame_rate_hz']:.3f} ms)")

    frame = amplitude[:Tf_samples]

    H_expected = cfg['img_height']
    W_expected = cfg['img_width']

    # Account for V_blank in line count
    total_rows = int(H_expected / (1 - cfg['v_blank_ratio']))
    Tr_samples = Tf_samples // total_rows
    Tr_us = Tr_samples / fs * 1e6
    print(f"  Estimated Tr  = {Tr_us:.2f} us (total {total_rows} rows, {H_expected} active)")
    print(f"  Samples/line  = {Tr_samples}")

    # Take only the active row portion
    active_frame = frame[:Tr_samples * H_expected]
    image_2d = active_frame.reshape(H_expected, Tr_samples)

    # Crop H_blank from the end of each row
    active_samples_per_line = int(Tr_samples * (1 - cfg['h_blank_ratio']))
    image_2d = image_2d[:, :active_samples_per_line]
    print(f"  Active samples/line: {active_samples_per_line}")

    # Downsample to expected width
    if active_samples_per_line >= W_expected:
        bin_size = active_samples_per_line // W_expected
        cropped = image_2d[:, :W_expected * bin_size]
        image_2d = cropped.reshape(H_expected, W_expected, bin_size).mean(axis=2)

    # Histogram normalization
    img_min, img_max = image_2d.min(), image_2d.max()
    if img_max > img_min:
        image_2d = (image_2d - img_min) / (img_max - img_min) * 255

    return image_2d.astype(np.uint8), Tf_ms, Tr_us


def compute_metrics(original, reconstructed):
    """SSIM/Corr/MSE metrics."""
    orig = original.astype(np.float64)
    recon = reconstructed.astype(np.float64)

    mse = np.mean((orig - recon) ** 2)
    orig_flat = orig.flatten() - orig.mean()
    recon_flat = recon.flatten() - recon.mean()
    if orig_flat.std() > 0 and recon_flat.std() > 0:
        corr = np.mean(orig_flat * recon_flat) / (orig_flat.std() * recon_flat.std())
    else:
        corr = 0.0

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


def visualize(original, iq, reconstructed, metrics, cfg, save_path):
    fs = cfg['sample_rate_msps'] * 1e6
    samples_per_frame = int(fs / cfg['frame_rate_hz'])

    fig, axes = plt.subplots(2, 2, figsize=(14, 9))

    axes[0, 0].imshow(original, cmap='gray', vmin=0, vmax=255)
    axes[0, 0].set_title(
        f'(a) HDMI source frame\n{original.shape[1]} x {original.shape[0]} '
        f'(scaled from 1920x1080)',
        fontsize=11
    )
    axes[0, 0].axis('off')

    amp_1f = np.abs(iq[:samples_per_frame])
    t_ms = np.arange(len(amp_1f)) / fs * 1000
    axes[0, 1].plot(t_ms, amp_1f, linewidth=0.3, color='steelblue')
    axes[0, 1].set_title(
        f'(b) Received IQ amplitude (1 frame @ 60 fps)\n'
        f'fc = {cfg["carrier_mhz"]} MHz (HDMI pixel clock harmonic)',
        fontsize=11
    )
    axes[0, 1].set_xlabel('Time (ms)')
    axes[0, 1].set_ylabel('|I + jQ|')
    axes[0, 1].grid(True, alpha=0.3)

    amp = np.abs(iq)
    _, coarse_vals, coarse_lags = estimate_tf(amp, fs, cfg['frame_rate_hz'])
    auto_norm = coarse_vals / np.max(np.abs(coarse_vals))
    lag_ms = coarse_lags / fs * 1000
    peak_lag_ms = coarse_lags[np.argmax(coarse_vals)] / fs * 1000

    axes[1, 0].plot(lag_ms, auto_norm, linewidth=1, color='darkgreen', marker='.', markersize=4)
    axes[1, 0].axvline(peak_lag_ms, color='red', linestyle='--',
                       label=f'Peak: {peak_lag_ms:.2f} ms')
    axes[1, 0].axvline(1000/cfg['frame_rate_hz'], color='gray', linestyle=':',
                       label=f'Expected: {1000/cfg["frame_rate_hz"]:.2f} ms')
    axes[1, 0].set_title('(c) Tf estimation via autocorrelation (60 Hz)', fontsize=11)
    axes[1, 0].set_xlabel('Lag (ms)')
    axes[1, 0].set_ylabel('Normalized autocorr')
    axes[1, 0].legend(loc='best', fontsize=9)
    axes[1, 0].grid(True, alpha=0.3)

    axes[1, 1].imshow(reconstructed, cmap='gray', vmin=0, vmax=255)
    axes[1, 1].set_title(
        f'(d) Reconstructed HDMI frame\n'
        f'SSIM={metrics["ssim"]:.3f}, Corr={metrics["corr"]:.3f}',
        fontsize=11
    )
    axes[1, 1].axis('off')

    plt.suptitle(
        'HDMI TEMPEST via Pluto SDR / LDSDR - Algorithm Pipeline Validation',
        fontsize=13, fontweight='bold'
    )
    plt.tight_layout()
    plt.savefig(save_path, dpi=120, bbox_inches='tight')
    print(f"\n  Visualization saved: {save_path}")
    return fig


def main():
    parser = argparse.ArgumentParser(description='HDMI TEMPEST PlutoSDR Simulation')
    parser.add_argument('--image', type=str, default=None)
    parser.add_argument('--output', type=str, default='output/hdmi_reconstructed.png')
    parser.add_argument('--vis', type=str, default='output/hdmi_simulation_result.png')
    parser.add_argument('--no-display', action='store_true')
    args = parser.parse_args()

    cfg = CONFIG.copy()
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    Path(args.vis).parent.mkdir(parents=True, exist_ok=True)

    print("=" * 72)
    print("  HDMI TEMPEST Simulation via PlutoSDR / LDSDR")
    print("  Adapted from EM Eye (NDSS 2024) - same algorithm, HDMI signal model")
    print("=" * 72)
    print()
    print(f"  Carrier        : {cfg['carrier_mhz']} MHz "
          f"(HDMI 1080p60 pixel clock 1st harmonic)")
    print(f"  Sample rate    : {cfg['sample_rate_msps']} MSPS (Pluto/LDSDR limit)")
    print(f"  Frame rate     : {cfg['frame_rate_hz']} Hz")
    print(f"  Image dims     : {cfg['img_width']} x {cfg['img_height']} "
          f"(scaled HD aspect)")
    print(f"  H_blank ratio  : {cfg['h_blank_ratio']*100:.1f}%")
    print(f"  V_blank ratio  : {cfg['v_blank_ratio']*100:.1f}%")

    t0 = time.time()

    print("\n[1/5] HDMI SOURCE")
    if args.image and os.path.exists(args.image):
        img = np.array(Image.open(args.image).convert('L').resize(
            (cfg['img_width'], cfg['img_height'])))
        print(f"  Loaded: {args.image}")
    else:
        img = generate_hdmi_test_image(cfg['img_width'], cfg['img_height'])
        print(f"  Generated HDMI test pattern: {img.shape}")
    src_path = Path(args.output).parent / 'hdmi_source.png'
    Image.fromarray(img).save(src_path)
    print(f"  Source saved: {src_path}")

    print("\n[2/5] TMDS LEAKAGE SIMULATION")
    print("  Modeling: pixel-clock harmonic emissions + H/V blanking")
    iq, _ = simulate_hdmi_leakage(img, cfg)
    print(f"  Samples generated: {len(iq):,}")
    print(f"  Duration: {len(iq)/(cfg['sample_rate_msps']*1e6)*1000:.1f} ms")

    print("\n[3/5] WIRELESS TRANSPORT")
    print(f"  192 Mbps (raw IQ) -> LDSDR Gigabit Ethernet -> PC")

    print("\n[4/5] EM EYE PIPELINE RECONSTRUCTION (adapted)")
    reconstructed, Tf_ms, Tr_us = reconstruct_hdmi(iq, cfg)
    print(f"  Output shape: {reconstructed.shape}")

    print("\n[5/5] METRICS")
    metrics = compute_metrics(img, reconstructed)
    print(f"  SSIM        : {metrics['ssim']:.4f}")
    print(f"  Correlation : {metrics['corr']:.4f}")
    print(f"  MSE         : {metrics['mse']:.2f}")

    Image.fromarray(reconstructed).save(args.output)
    print(f"  Reconstructed saved: {args.output}")

    fig = visualize(img, iq, reconstructed, metrics, cfg, args.vis)

    elapsed = time.time() - t0
    print(f"\nTotal runtime: {elapsed:.1f}s")

    print("\n" + "=" * 72)
    print("  HDMI TEMPEST simulation complete!")
    print("=" * 72)
    print("\nNotes on real-hardware deployment:")
    print("  1. Place near-field H probe (Beehive 100C / Aaronia) close to HDMI cable")
    print("  2. Tune Pluto to 148.5 MHz (1080p60 pixel clock 1st harmonic)")
    print("     Other targets: 297 MHz (2nd harmonic), 1485 MHz (TMDS bit clock)")
    print("  3. Capture at 8-30 MSPS (Pluto/LDSDR max)")
    print("  4. Use this script's reconstruct_hdmi() unchanged")
    print()
    print("Expected real-world performance:")
    print("  - Distance: < 30 cm with near-field probe (cf. EM Eye 30cm-5m)")
    print("  - SSIM: 0.2-0.5 (vs EM Eye paper Table I 0.3-0.6 for cameras)")
    print("  - Resolution: ~20-50 effective horizontal pixels")
    print("    (since 8 MSPS << 148.5 MHz pixel rate)")
    print()

    if not args.no_display:
        try:
            plt.show()
        except Exception:
            pass


if __name__ == '__main__':
    main()
