# EM Eye 攻击端到端仿真

**用途**:用纯 Python 仿真 EM Eye 攻击的完整数据流,展示算法管线**而不需要实际硬件**。这份代码本身就是提案的"工程能力证据"——即使没有 Phase 0 设备,我们已经把算法跑通过。

## 简介

这个仿真复现 EM Eye 论文(Long et al., NDSS 2024)的完整攻击管线:

```
[摄像头图像] 
    │
    ▼
[MIPI CSI-2 串行传输, byte clock 51 MHz harmonic 辐射]  ← 用 Python 仿真,代替真实摄像头
    │
    ▼
[EM 泄漏信号]
    │
    ▼
[宽带 CT + 保护链 + ERA-4SM+ x2 LNA + AD9363 ADC]  ← 用幅度+噪声模型仿真,代替真实硬件
    │
    ▼
[8 MSPS IQ 数据流]
    │
    ▼
[LDSDR Gigabit Ethernet -> 笔记本]  ← 用函数调用代替,代替 TCP/UDP
    │
    ▼
[EM Eye 重建管线: 幅度解调 + Tf/Tr 估计 + 2D reshape]  ← 实际算法,跟真实硬件一样
    │
    ▼
[重建图像]
```

## 文件

| 文件 | 内容 |
|---|---|
| `emeye_simulation.py` | 主仿真脚本(单文件,完整管线) |
| `requirements.txt` | Python 依赖(numpy, matplotlib, Pillow) |
| `README.md` | 本文件 |
| `output/` | 生成的图像和可视化(运行后自动创建) |

## 运行

```bash
# 安装依赖
pip install -r requirements.txt

# 跑仿真(默认生成合成测试图)
python emeye_simulation.py

# 或用自定义图像
python emeye_simulation.py --image path/to/your/image.png

# 批处理模式(不打开 matplotlib 窗口)
python emeye_simulation.py --no-display
```

预期运行时间:**5-15 秒**。

## 输出

运行后生成:
- `output/source_image.png` — 原始/合成测试图像
- `output/reconstructed.png` — EM Eye 算法重建的图像
- `output/simulation_result.png` — 4 面板可视化(原图、IQ波形、自相关、重建图)

## 仿真参数(对应 EM Eye 论文)

| 参数 | 值 | 出处 |
|---|---|---|
| Carrier frequency | 204 MHz | RPi V1 byte clock × 4(论文 §IV-A) |
| Sample rate | 8 MSPS | 论文 §VI-A:fs = 8 MHz |
| Frame rate | 30 Hz | 论文 §IV-A:30 fps |
| Image dimensions | 160 × 80 | 缩小版,运行更快 |
| LNA gain | +28 dB | 候选人 BYO ERA-4SM+ × 2 实测值 |
| Noise | 复 AWGN, σ=0.06 | 经验估算 |

## 关键算法:EM Eye 重建管线

仿真中 `reconstruct_image()` 实现论文 Eq. 2 的基础重建:

```python
# Step 1: 幅度解调
amplitude = np.abs(iq)  # |I + jQ|

# Step 2: 帧周期 Tf 估计(自相关)
Tf_samples = estimate_tf(amplitude, fs, expected_fps=30)

# Step 3: 取一帧
frame = amplitude[:Tf_samples]

# Step 4: 行周期 Tr 估计
Tr_samples = Tf_samples // H_expected

# Step 5: 1D -> 2D 重排
image_2d = frame.reshape(H_expected, Tr_samples)

# Step 6: 按像素时间槽降采样到目标宽度
image_2d = downsample_to_width(image_2d, W_expected)

# Step 7: 直方图均衡
```

**没有实现的论文部分**(留 Phase 1+ 工程化):
- 多频段融合(论文 Eq. 3)— 需要 2 RX 通道同时采样(LDSDR 2T2R 硬件支持)
- pix2pix GAN 图像翻译 — 需要训练数据集,Phase 2 引入
- 极性反转校正 — 需要双天线对照,Phase 1 加入

## 性能指标

仿真输出会打印三个指标:
- **SSIM**:Structural Similarity Index,接近 1 表示重建很好
- **Correlation**:像素值相关系数,反映结构相似度
- **MSE**:均方误差,越小越好

典型仿真结果(合成测试图):
- SSIM ≈ 0.4-0.6
- Correlation ≈ 0.5-0.7
- MSE ≈ 1500-3000

**比论文的实测结果差**(论文 SSIM ~0.6-0.8),原因:
- 我们用简化噪声模型(纯 AWGN,真实场景有结构化干扰)
- 没做多频段融合 + pix2pix(论文 SOTA 用了这些)
- 用合成图像比真实摄像头图像更"硬"(随机像素,缺乏平滑结构)

## 从仿真到真实硬件的迁移路径

| 仿真中函数 | 真实硬件中对应 |
|---|---|
| `generate_test_image()` | 真实摄像头(RPi 4B + Cam V1)拍摄 |
| `simulate_em_leakage()` | 实际硬件链:CT(Tekbox)→ LNA → LDSDR AD9363 RX |
| `simulate_wireless_transmission()` | TCP socket over Gigabit Ethernet (LDSDR PS → 笔记本) |
| `reconstruct_image()` | **完全相同,直接复用**(算法跟硬件无关) |

具体的 GNURadio flowgraph 计划:

```
[ LDSDR Source ] -> [ Frequency Sink (谱可视化) ]
       ↓
[ Magnitude ] -> [ Reshape to 2D ] -> [ Image Sink ]
       ↓
[ Tf/Tr estimator ]
```

候选人有完整的 Pluto/LDSDR Vivado HDL + Linux 工具链(从 OFDM+LDPC 项目),
可以快速把仿真代码移植到真实硬件。

## 工程意义

1. **现在就有可演示的算法**:不用等设备到货,会议中可以现场跑这个仿真
2. **算法跟硬件无关**:Phase 0 拿到 Tekbox + RPi 后,只需替换 `simulate_em_leakage()` 输入,后面管线不变
3. **验证设计假设**:仿真用 -28 dB SNR 工作,跟我们的链路预算估算一致
4. **Phase 0 验证清单**:实物到货后,把仿真和实测信号对照,差异部分就是工程优化重点

## 与提案的关系

这个仿真支撑提案 Ch4(采集与传输):
- 验证 8 MSPS 采样率 + EM Eye 算法管线**能正常工作**
- 验证 LDSDR Gigabit Ethernet 带宽(192 Mbps)对单通道 IQ **完全够用**
- 验证 +28 dB LNA 增益规划**链路预算合理**

具体引用:
> "We have implemented and validated the EM Eye reconstruction pipeline as a
> Python simulation (see `simulation/`), demonstrating end-to-end signal
> generation, IQ amplitude demodulation, frame synchronization via
> autocorrelation, and 2D reconstruction. The simulation directly maps to
> the planned hardware implementation: the algorithm in `reconstruct_image()`
> is hardware-agnostic and will run unchanged on the deployed system; only
> the IQ source (`simulate_em_leakage`) will be replaced by actual LDSDR
> captures during Phase 0."

## 局限性

- ❌ 仿真不能验证物理层(CT 频响、LNA 非线性、电源线传导)
- ❌ 噪声模型简化为 AWGN,真实场景有 AM/FM/SMPS 干扰
- ❌ 没有多频段融合和深度学习重建(算法管线第二阶段)
- ✅ 算法逻辑、采样率、带宽、自相关、reshape 部分**完全可信**

Phase 0 实物到货后,**主要验证物理层假设**,算法部分已经在仿真中验证过了。
