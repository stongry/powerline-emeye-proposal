# EM Eye 论文笔记(NDSS 2024)

引用:Yan Long, Qinhong Jiang, Chen Yan, et al. *EM Eye: Characterizing Electromagnetic Side-channel Eavesdropping on Embedded Cameras.* NDSS 2024.
论文 PDF:https://yanlong.site/files/ndss24-emeye.pdf

本笔记浓缩与**前端采集相关**的所有事实(写提案 Ch2-4 必查的参数清单)。

---

## 1. 攻击原理(§III)

- 目标:CMOS 摄像头 + ISP 之间 MIPI CSI-2 数据传输线产生的非故意电磁辐射
- 数据切换在数据线上产生高频电流 → 线缆作为"非故意天线"辐射 EM 波
- 攻击者用 SDR 在数百 MHz – GHz 带内接收,通过幅度解调重建图像
- 论文金句(写提案要引用):*"the cable that connects the image sensor and ISP acts as an unintentional transmission antenna and propagates the EM waves to the adversary's receiving antenna"*
- 两种攻击场景:HA(Hidden Antenna, <10 cm 近场)/ PI(Physical Isolation, >10 cm 远场含穿墙)

---

## 2. 论文使用的前端硬件(Appendix H)

完整的"中端"侧信道接收系统,总成本 ~$2322:

| 模块 | 型号 | 关键参数 | 价格 |
|---|---|---|---|
| **SDR** | Ettus **USRP B210** | 70 MHz – 6 GHz, 56 MHz BW, 12-bit, 双通道 | $2100 |
| **LNA** | Foresight Intelligence **FST-RFAMP06** | DC – 3.5 GHz, **40 dB** 增益 | $207 |
| **天线(远场)** | 通用户外 **LPDA**(对数周期定向) | 700 – 4900 MHz, 15 dBi | $15 |
| **探头(近场)** | "tiny near-field magnetic probe"(具体型号未给出) | <10 cm 用 | — |
| **上位机** | Laptop(具体型号未给) | 跑重建算法 | — |

⚠️ 论文明确说这是中端,提到 resourceful adversary 可换:
- 专业 >30 dBi 天线
- 高端 LNA up to 50 dB
- 模拟带通滤波(参考已有 TEMPEST 工作把距离从 10 m 推到 80 m)

---

## 3. 关键采样参数

### 3.1 采样率(全文最反直觉的细节)

> 论文原文(§VI-A):*"We use an EM sampling rate (fs) of 8 MHz in all experiments."*

> 论文原文(§IV-B3):*"we can only sample a bandwidth of 10 MHz with common USRPs and laptops while digital image transmissions have bandwidths on the order of 1 GHz."*

**洞察**:
- MIPI 数据传输实际带宽在 **GHz 级**
- 但 USRP B210 + Laptop 受 USB 3.0 实际吞吐限制,**单次只能 ~10 MHz 带宽**
- 论文作者**主动放弃覆盖全带宽**,只在 MIPI byte-clock 谐波附近 8 MHz 窄带采样
- **能成功的根本原因**:图像信息以幅度调制叠在 byte-clock 谐波上,采任意一个谐波附近 8 MHz 就足以提取图像幅度包络

### 3.2 中心频率选择 = MIPI byte-clock 谐波

> 论文原文:*"For RPi V1, fclk is measured to be 204 MHz, which means the byte transmission frequency is 51 MHz."*

针对 RPi V1,他们选 **204 MHz 和 255 MHz** = 51 MHz × 4 和 51 MHz × 5(byte clock 的 4 倍 / 5 倍谐波)。

### 3.3 COTS 设备频点表(Table II 摘录)

**这张表对提案极其重要 — 直接告诉你哪些频点要放进 SDR preset**:

| # | 设备 | 频点 1 (MHz) | 频点 2 (MHz) | 最大距离 |
|---|---|---|---|---|
| 1 | Google Pixel 1 (2013) | 600 | 1649 | 30 cm |
| 2 | Google Pixel 3 (2018) | 515 | 680 | 2 cm |
| 3 | Samsung S6 (2015) | 527 | 1054 | 5 cm |
| 4 | ZTE Z557 (2019) | 522 | 1740 | 1 cm |
| 5 | Wyze Cam Pan 2 (2019) | 890 | 1185 | **350 cm** |
| 6 | Xiaomi Dafang (2019) | 322 | 890 | **500 cm** |
| 7 | Baidu Xiaodu X9 (2023) | 204 | 1470 | 200 cm |
| 8 | TeGongMao (2023) | 763 | 1144 | 120 cm |
| 9 | Goov V9 (2022) | 546 | 656 | 70 cm |
| 10 | QiaoDu (2021) | 293 | 1191 | 50 cm |
| 11 | 360 M320 行车记录仪 (2020) | 450 | 1261 | 250 cm |
| 12 | Blackview 行车记录仪 (2022) | 155 | 1015 | 300 cm |

**规律**:
- 主要在 **155 MHz – 1.74 GHz**
- 手机偏高(500 MHz – 1.7 GHz),家用摄像头/行车记录仪偏低(155 MHz – 1.2 GHz)
- 多数避开 WiFi/GSM/LTE 主频段

---

## 4. 信号链(Fig. 8 + Fig. 16)

### 拓扑 A:近场(HA, <10 cm)
```
[摄像头 MIPI 排线] → [近场磁探头] → 同轴 → [LNA: FST-RFAMP06, +40 dB] → [USRP B210, fs=8 MSPS] → USB 3.0 → [Laptop]
```

### 拓扑 B:远场/穿墙(PI, >10 cm,最远 5 m)
```
[摄像头辐射] →(空气/墙)→ [LPDA 定向, 15 dBi] → [LNA +40 dB] → [USRP B210] → [Laptop]
```

**关键**:论文**没有用模拟带通滤波器**,仅 Appendix F 提到加 BPF 是"可改进点"。

---

## 5. 解调与重建(§V)

### 5.1 解调
- **幅度解调**:`pixel_gray = |I + jQ|`(论文 §IV-B2 + §V-A Eq. 2)
- 完全在软件做,USRP 输出 IQ 流

### 5.2 重建流程(§V Fig. 7)
1. 设定 USRP 中心频率 → 输出复 IQ 流(8 MSPS)
2. 计算每个 IQ 样本振幅
3. 用估计出来的 **帧周期 Tf** 和 **行周期 Tr**,把 1D 振幅序列折叠成 2D 图像
4. 多频段融合(Eq. 3):`Î_EM = Σ wᵢ · I_EM_[lᵢ,hᵢ]`,典型 N=1–3
5. **pix2pix GAN** 做 image-to-image translation → 最终 I_EM(去除论文 §IV-B3 提到的"sampling distortion")

### 5.3 帧/行同步参数估计(Appendix D)
- Tf(帧周期)和 Tr(行周期)用**信号自相关 + trial-and-error** 估计
- 估出 Tf 和 Tr 后,raw_height = Tf / Tr
- 这是个**与 OFDM 同步问题结构相似的**信号处理任务,可类比

---

## 6. 接收距离记录(Section VI + Table II)

| 类别 | 最大距离 |
|---|---|
| 智能手机 | ≤ 30 cm |
| 家用摄像头 | 50–500 cm |
| 行车记录仪 | 250–300 cm |
| 通用上限(用 45 dBi LPDA + BPF) | 80 m(引用前人 TEMPEST 工作) |

8/12 台 COTS 设备能在 PI 场景(穿墙)实现窃听。

---

## 7. 写提案时**必须引用**的论文段落

1. **§III "cable acts as unintentional transmission antenna"** — Ch2 §2.1 用来论证电源线同理
2. **§IV-B3 "fs = 10 MHz limitation"** — Ch4 §4.2 用来论证窄带采样的合理性
3. **§VI-A "fs = 8 MHz in all experiments"** — Ch4 §4.2 用来对齐我方采样率选择
4. **Appendix F "analog filters significantly reduce noise"** — Ch3 §3.3 用来论证 BPF 是 SNR 改进项
5. **Appendix H 设备清单** — Ch3 §3.1 和 Ch5 BOM 用来对标
6. **Table II 频点表** — Ch4 §4.2 / Ch5 频点 preset

---

## 8. 论文**没说但提案要解决**的问题

1. ❓ 电源线传导(论文用空气辐射)在 100M–1G 段衰减多少? → Ch2 §2.5 标为已知风险,Ch6 提议 Phase 0 实测
2. ❓ 宽带 CT 在 1 GHz 是否可行?Fair-Rite 磁芯到底能撑多高频? → Ch2 §2.5 标风险
3. ❓ COTS 设备在电源线上和在空气上的频点是否一致?(很可能一致,因为源信号本身没变) → 这是 Phase 1 必测项

---

## 9. 论文中提到的相关工作(写提案要顺带引用 2-3 篇)

经典 TEMPEST:
- **Wim van Eck (1985)** — 首篇可重建视频显示的非军用研究 [39]
- **Markus Kuhn (2002)** — 低成本 CRT/LCD 窃听 [21], [22]
- **Hayashi et al.** — 平板/笔记本屏幕 2 m 距离窃听 [14]
- **Liu et al. (recent)** — 智能手机屏幕窃听 (1 cm 距离 + ML)
- **Genkin et al. [12]** — 声学侧信道屏幕窃听

写提案 Cover/Intro 时,可以这样建立 narrative:
> "Following the line of TEMPEST research from van Eck (1985) on CRT eavesdropping, Kuhn (2002) on LCD displays, Hayashi et al. on small displays, and recently EM Eye (Long et al., NDSS 2024) on embedded cameras, this proposal addresses the next natural step — extending the EM-leakage attack surface to power-line conducted emanations."

这一句话能立刻把审稿人(本身就是这条研究链的主要贡献者)拉进熟悉的语境。
