# 相关工作文献调研

**用途**:写提案 Cover/Intro 时引用 + Ch2 物理机制章节的对照支撑。

每条目格式:
- **作者 (年份)**:论文标题 [会议/期刊]
- 摘要 1 句话
- 对本提案的可引用点

---

## 组 1:电源线传导侧信道 / TEMPEST 历史经典

> 关键词:`power-line conducted EM emanations`, `TEMPEST conducted`, `cable EMI side channel`

### Wim van Eck (1985) — TEMPEST 的开山之作
- **van Eck, Wim**. "Electromagnetic Radiation from Video Display Units: An Eavesdropping Risk?" *Computers & Security*, 1985.
- 首次证明用非军用商业级设备可以重建 CRT 视频显示内容
- **可引用点**:奠定了"数据传输 → EM 辐射 → 远程重建"的研究范式;本提案是该范式向"电源线传导路径 + 嵌入式摄像头"的扩展

### Markus Kuhn (2002) — CRT 显示器低成本窃听
- **Kuhn, Markus G.**. "Optical Time-Domain Eavesdropping Risks of CRT Displays." *IEEE Symposium on Security and Privacy*, 2002.
- 系统化分析 CRT 显示在不同条件下的可窃听性
- **可引用点**:本提案的"模拟带通滤波改进 SNR"思路可追溯至 Kuhn 工作

### Markus Kuhn (2013) — LCD 显示器 EM 窃听
- **Kuhn, Markus G.**. "Compromising Emanations of LCD TV Sets." *IEEE Transactions on EMC*, 2013.
- 把 TEMPEST 范式扩展到现代 LCD,提出更通用的重建管线
- **可引用点**:论证显示设备的发展不改变 TEMPEST 风险存在

### Hayashi et al. (2014) — 平板/笔记本远程窃听
- **Hayashi, Yuichi, et al.**. "A Threat for Tablet PCs in Public Space: Remote Visualization of Screen Images Using EM Emanation." *ACM CCS*, 2014.
- 证明小屏幕设备(平板/笔记本)2 m 距离仍可重建
- **可引用点**:论证 EM 攻击对低功耗嵌入式设备同样有效,与 EM Eye 主张呼应

### de Meulemeester et al. (2020) — 80 米超长距离窃听
- **de Meulemeester, Pieterjan, et al.**. "Eavesdropping a (Ultra-) High-definition Video Display from an 80 Meter Distance under Realistic Circumstances." *IEEE EMCSI*, 2020.
- 用 45 dBi LPDA + 模拟 BPF + 改进算法,从 80 米外重建 UHD 显示
- **可引用点**:论证更高端硬件可显著延伸窃听距离(EM Eye 引用过这篇)

### Hayashi et al. — 工业现场的传导泄漏(待补)
- 关键词:`Hayashi conducted emission`
- TODO:补具体引用

---

## 组 2:宽带电流互感器 (CT) 设计

> 关键词:`broadband ferrite current transformer`, `EMC current probe`, `wideband CT 1 GHz`

### Pearson Electronics — 商用 CT 标杆
- **Pearson Electronics Model 411 Current Monitor** (产品手册)
- 5 Hz – 20 MHz, 0.1 V/A,工业标准
- **可引用点**:商业 CT 普遍上限 20-100 MHz,本提案需要做到 1 GHz,是工程创新点

### Fischer Custom Communications F-65A — RF 段宽带 CT
- 10 kHz – 1 GHz, EMC 测试用
- **可引用点**:证明铁氧体 CT 在 1 GHz 是可行的,但商品体积大(~150 mm),需自研小型化版本

### Fair-Rite Application Note — 磁芯材质选择
- **Fair-Rite Products Corp.** "Material Selection Guide for Common-Mode Chokes"
- #43, #61, #52 材质频响曲线
- **可引用点**:Ch2 §2.3 的材质选择直接引用此应用笔记

---

## 组 3:Pluto SDR + Zynq HDL 开发

> 关键词:`ADALM-Pluto firmware HDL`, `AD9361 Zynq custom firmware`

### Analog Devices — Pluto Firmware Source (GitHub)
- github.com/analogdevicesinc/plutosdr-fw
- 标准 Buildroot Linux + 默认 HDL bitstream
- **可引用点**:Ch4 Sidebar 板上加速 — 论证我方能在此基础上插入自研 PL 模块

### Analog Devices — HDL Reference Designs
- github.com/analogdevicesinc/hdl
- 包含 AD9361 接口、AXI 总线、各类示例工程
- **可引用点**:候选人 OFDM+LDPC 项目基于这一套,熟悉度高

---

## 组 4:摄像头 EM 检测 / 注入(EM Eye 的"前置工作")

> 关键词:`hidden camera EM detection`, `camera EM injection`

### Chaman et al. (2018) — Ghostbuster
- **Chaman, Anadi, et al.**. "Ghostbuster: Detecting the Presence of Hidden Eavesdroppers." *ACM MobiCom*, 2018.
- 用 EM 检测隐藏摄像头是否开机(1 bit 信息)
- **可引用点**:与 EM Eye 形成对比 — Ghostbuster 提取 1 bit,EM Eye 提取整张图;**本提案进一步把信道从空气扩展到电源线**

### Jiang et al. — EM 注入控制摄像头输出
- **Jiang, Qinhong, et al.**. "GhostImage..." (EM Eye 引用 [19])
- CMOS 摄像头被 EM 干扰可输出受控图像内容
- **可引用点**:论证摄像头 EM 通道**双向**敏感(注入 + 泄漏),本提案聚焦泄漏方向

---

## 写提案时如何串联这些引用(narrative 草稿)

> "Building on four decades of TEMPEST research originating from van Eck's seminal 1985 work on CRT eavesdropping [1], extended by Kuhn to LCD displays [2,3], by Hayashi et al. to mobile devices [4], and by de Meulemeester et al. to 80-meter UHD eavesdropping [5], EM Eye (Long et al., NDSS 2024) [6] recently demonstrated that embedded cameras are also vulnerable to this physical-layer attack. Whereas all prior work assumes over-the-air radiation as the leakage path, **this proposal extends the attack surface to power-line conducted leakage** — a path that, in principle, is not bounded by the air-propagation distance limits observed in EM Eye (5 m for home cameras, 30 cm for smartphones)."

这一段在 Ch0 (Executive Summary) 和 Ch2 (Physical Mechanism) 各用一次,可显著提升论文气质。

---

## TODO(Day 1 下半天)

- [ ] 用 Google Scholar 查每条引用的完整书目信息(DOI / 页码 / 出版商)
- [ ] 至少补 1 篇"conducted side channel"的实证论文(目前略空)
- [ ] 整理 BibTeX 形式存档以便 Day 4 写 References 时直接拷贝
