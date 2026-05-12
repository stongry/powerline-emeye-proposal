# Power-Line Side-Channel Acquisition Device — Design Proposal

> **状态**:草稿模板,逐日填充
> **目标语言**:英文(目标受众 U Michigan 实验室)
> **提交日期**:2026-05-17

---

## Cover

**Title**: Power-Line Side-Channel Acquisition Device — Design Proposal
**Subtitle**: Extending EM Eye to Power-Line Conducted Leakage
**Candidate**: [姓名] · [Email] · [WeChat]
**Target**: Research Assistant position, Yan Long Lab, University of Michigan
**Date**: 2026-05-17

---

## §0 Executive Summary

> [Day 5 撰写] — 一段话 + 4 个 bullet

This proposal describes the design of a miniaturized acquisition device that extends the EM Eye eavesdropping attack (Long et al., NDSS 2024) from over-the-air electromagnetic radiation to **power-line conducted leakage**. ...

- **Form factor**: portable integrated unit (150 × 80 × 50 mm), with plug-in adapter as Phase 2 evolution
- **Key novelty**: power-line conducted leakage coupling via broadband ferrite current transformer
- **Acquisition**: ADALM-Pluto SDR (70 MHz – 6 GHz, 12-bit IQ at 8–20 MSPS), tuned to MIPI byte-clock harmonics
- **Differentiator**: candidate's prior implementation of OFDM+LDPC transceiver on ADALM-Pluto's Zynq-7010 enables FPGA-side acceleration roadmap

---

## Ch1 — Form Factor, Dimensions & System Block Diagram

> [Day 2 撰写]

### 1.1 Form Factor Decision

[Route A vs Route B 论证]

### 1.2 Dimensional Budget

[150 × 80 × 50 mm 内的子系统分配]

### 1.3 System Block Diagram

**Figure 1**: [系统框图占位]

---

## Ch2 — Power-Line High-Frequency Leakage Coupling & Extraction

> [Day 2 撰写] ⭐ 关键章节

### 2.1 Physical Mechanism

The EM Eye paper establishes that *"the cable that connects the image sensor and ISP acts as an unintentional transmission antenna and propagates the EM waves to the adversary's receiving antenna"* [Long et al., §III]. We extend this observation to the **power-supply cabling** of the device under test. ...

### 2.2 Coupling Method Trade-off

**Table 1**: Coupling method comparison

| Method | Bandwidth | Mains Isolation | Volume | Safety | Choice |
|---|---|---|---|---|---|
| Broadband CT | 1 MHz – 1 GHz | Excellent | Compact | High | **Primary** |
| Capacitive coupling | DC – several GHz | Poor | Very compact | Lower | Secondary |
| Mini-LISN | Defined narrow | Built-in | Large | Standard | Rejected |

### 2.3 Selected Architecture

[宽带 CT + 电容辅路的具体设计]

### 2.4 Protection & Mains Isolation Chain

[GDT / MOV / CM choke / TVS / DC-block / LC HPF 详述]

### 2.5 Known Risks

[>500 MHz 磁芯不确定 + 损耗未知]

**Figure 2**: Coupling and protection schematic.

---

## Ch3 — Analog Frontend Design

> [Day 3 撰写]

### 3.1 Architecture

[40 dB total gain, NF<3 dB, 100M–1G flat]

### 3.2 Link Budget

**Table 2**: Frontend link budget

| Stage | Signal | Noise | Cumulative Gain | NF |
|---|---|---|---|---|
| Coupler input | −80 dBm | −120 dBm/Hz | 0 dB | — |
| Coupler output | −85 dBm | … | −5 dB | 5 dB |
| LNA output | −45 dBm | −90 dBm/Hz | 35 dB | ~3 dB |

### 3.3 Optional Switchable BPF Bank

[引用 EM Eye Appendix F]

### 3.4 PCB & Shielding

[4-layer, Rogers RO4350B, tin-can over LNA]

**Figure 3**: LNA module schematic.

---

## Ch4 — Acquisition & Wireless Transmission

> [Day 3 撰写]

### 4.1 SDR Selection — ADALM-Pluto

[选型 + 候选人 Pluto 经验突出]

### 4.2 Sampling Strategy

[fs = 8–20 MSPS, 锁 MIPI byte-clock 谐波,频点 preset table 来源于 EM Eye Table II]

### 4.3 Transmission Decision

**Table 3**: Raw IQ vs board-side reconstruction

| Approach | Wireless BW | Host Compute | Flexibility | Latency |
|---|---|---|---|---|
| Raw IQ over WiFi 6 | 192 Mbps | High | Maximum | High |
| Board-side reconstruction | <30 Mbps | Low | Fixed | Low |

### 4.4 Wireless Module

[WiFi 6 RTL8852BE]

### 4.5 Host SoC

[Raspberry Pi CM4]

### 4.6 [Sidebar] Board-Side Acceleration Roadmap

> [Day 5 精修] — 差异化亮点

Leveraging the candidate's prior experience implementing an OFDM+LDPC transceiver on the ADALM-Pluto platform (Zynq xc7z010, BER=0 board-level validation), we propose a Phase-2 enhancement: modifying Pluto's PL fabric to implement (i) amplitude demodulation `|I+jQ|` in pipelined integer arithmetic, and (ii) coarse frame synchronization via 30 Hz autocorrelation. This reduces the wireless throughput requirement from 192 Mbps (raw IQ) to ~30 Mbps (demodulated stream), enabling deployment over WiFi 4 or Bluetooth 5.0, and lowering host computational load. ...

**Figure 4**: Digital subsystem block diagram.

---

## Ch5 — Key Component Selection

> [Day 4 撰写]

**Table 4**: BOM with primary / alternate / rationale

[完整 BOM 表,见 OUTLINE.md]

---

## Ch6 — Cost Estimate

> [Day 4 撰写]

### 6.1 BOM Cost(Route A, single prototype)

**Total**: ~ ¥4,350

### 6.2 NRE Cost

**Total**: ~ ¥5,300

### 6.3 Labor

1 RA × 6 months
- Phase 0 (feasibility): 3 weeks
- Phase 1 (engineering prototype): 3 months
- Phase 2 (integration + validation): 2 months

### 6.4 Phased Delivery

[Phase 0/1/2 详述]

---

## §7 Risks & Open Questions

> [Day 4 撰写]

- Power-line propagation loss in 100 MHz – 1 GHz band is unknown until measured
- Ferrite-core CT bandwidth uncertainty above 500 MHz
- COTS device leakage variance across 12 EM Eye targets via power-line
- Regulatory: EMC Class B + IEC 61010 safety
- ADALM-Pluto supply chain

---

## Annex A — Candidate Relevant Experience

> [Day 4 撰写]

| Project | Hardware Platform | Outcome | Repo |
|---|---|---|---|
| OFDM+LDPC PlutoSDR Transceiver | Zynq xc7z010 (Pluto) | BER=0 board-level | private |
| XCZU3EG PL Plate-Recognition CNN | Zynq UltraScale+ | 87.94% / 675ms | github.com/stongry/FPGA-ZYNQ |
| RK3568 Ubuntu Port + RKNN NPU | Rockchip + NPU | Production embedded Linux + edge AI | private |
| EC800M Voice AI | Quectel cellular | Full wireless integration | private |
| Smart-Home Slint UI | RK3588 panel | 62.97 fps (panel limit) | private |

These projects collectively span every technical layer required by the proposed device: HDL on Pluto-Zynq, FPGA-side acceleration, embedded Linux on ARM SoC, wireless integration, and full system integration.

---

## References

1. Y. Long, Q. Jiang, C. Yan, et al., *EM Eye: Characterizing Electromagnetic Side-channel Eavesdropping on Embedded Cameras*, NDSS 2024.
2. W. van Eck, *Electromagnetic Radiation from Video Display Units: An Eavesdropping Risk?*, Computers & Security, 1985.
3. M. G. Kuhn, *Optical Time-Domain Eavesdropping Risks of CRT Displays*, IEEE S&P, 2002.
4. M. G. Kuhn, *Compromising Emanations of LCD TV Sets*, IEEE T-EMC, 2013.
5. Y.-i. Hayashi, et al., *A Threat for Tablet Pcs in Public Space: Remote Visualization of Screen Images Using EM Emanation*, ACM CCS, 2014.
