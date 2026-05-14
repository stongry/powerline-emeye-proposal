# 提案大纲 — 电源线侧信道采集设备

本大纲是提案的写作蓝图。每一节列出必须覆盖的内容、必备图表、推荐篇幅。

结构严格遵循功能需求书规定的 6 章框架,补充封面、风险段、候选人经验 Annex。

最终提案 PDF **纯中文撰写**(PhD 反馈非常积极,匹配要求,需要尽快出一份完整工程文档)。

---

## 源文档对照表(写每一段前必查)

提案中的每一处 claim,都必须能追溯到下列两份源文档之一。这是自检清单。

| 提案要素 | EM Eye 论文锚点 | 功能需求书锚点 |
|---|---|---|
| 形态尺寸 <15×8×5 cm | — | 需求书 §设备形态要求 |
| 电源线传导泄漏前提 | §III "cable acts as unintentional transmission antenna" | 需求书 §背景(团队新发现) |
| 耦合网络(CT/电容/LISN) | —(论文仅用近场探头/LPDA) | 需求书 Function 1 电磁信号耦合 |
| 保护与滤波链 | Appendix F "analog filters significantly reduce noise" | 需求书 Function 2 阻抗匹配/保护/滤波 |
| LNA 30–40 dB | Appendix H: FST-RFAMP06 @ 40 dB | 需求书 Function 2 低噪声放大 30–40 dB |
| 频段 100 MHz – 1 GHz | Table II: 155 MHz – 1740 MHz across 12 devices | 需求书 Function 3 100 MHz – 1 GHz |
| IQ 采样率 >10 MSPS | §VI-A: fs = 8 MHz baseline | 需求书 Function 3 大于 10 MHz |
| 固定频点回退方案 | §III: USRP tuned to one band at a time | 需求书 Function 3 "若硬件资源有限,可以先实现固定频点采集" |
| 各摄像头频点表 | Paper Table II (12 COTS) | — |
| 无线传输 | —(论文用 USB 到笔记本) | 需求书 Function 4 支持原始 IQ 数据无线传输 |
| 原始 IQ vs 板上重建 | §V 重建管线(pix2pix on PC) | 需求书 Function 4 "若无线传输带宽不足,可考虑板上创建图像后无线传输" |

写每段前问自己:"这句话能锚在表格里哪一行?"如果锚不上,可能是过度发挥,要删或要再找依据。

---

## 封面页(½ 页)

- 标题:**Power-Line Side-Channel Acquisition Device — Design Proposal**
- 副标题:Extending EM Eye to Power-Line Conducted Leakage
- 候选人姓名 + 联系方式
- 申请目标:RA position, Yan Long Lab
- 日期:2026-05-17

---

## §0 Executive Summary(½ 页)

一段话 + 4 个 bullet:
- 设计目标(1 句话)
- 价值(EM Eye 延伸到电源线场景的意义)
- 核心技术决策(形态、耦合、SDR、传输)
- 分阶段交付计划
- 候选人相关经验(1 行 teaser,详见 Annex)

---

## Ch1 — 总体形态、尺寸、系统框图(1 页)

**必含内容**:
- 形态选择:便携集成式(Route A,风险低)vs 插头适配式(Route B,Phase 2 演进)
- 选 Route A 的理由
- 尺寸预算:150 × 80 × 50 mm 内
- **Figure 1**:总体系统框图(7 模块:耦合 → 保护 → 滤波 → LNA → SDR → 主控 → 无线)
- 简述 Phase 2 向插头形态演进路线

**篇幅**:1 页含图。

---

## Ch2 — 电源线高频泄漏耦合与提取(2–3 页)⭐ 关键章节

这是整份提案的**技术心脏**。审稿人(EM Eye 论文作者)主要靠这一章判断"这个候选人懂不懂 EM 物理"。

### §2.1 物理机制
- CMOS + MIPI 总线如何在电源线上产生共模(CM)电流
- 为什么这些 CM 电流以传导电磁辐射形式传播
- 引用并扩展 EM Eye 论文 §III 的论点 *"cable acts as unintentional transmission antenna"* — 论证该论点同样适用于电源线
- 预期频率范围 100 MHz – 1 GHz(对应 EM Eye Table II 的 byte-clock 谐波)

### §2.2 耦合方式权衡
**Table 1**(必须):

| 方式 | 频响 | 工频隔离 | 体积 | 安全性 | 选择 |
|---|---|---|---|---|---|
| 宽带 CT(铁氧体磁芯电流互感器) | 1 MHz – 1 GHz | 优(电气隔离) | 紧凑 | 高 | **主选** |
| 电容耦合(HV 陶瓷电容) | DC – 数 GHz | 差(电容短路风险) | 极紧凑 | 中 | 辅助/双通道 |
| 微型 LISN | 限定窄带 | 自带 | 大 | 标准 | 否决(体积) |

### §2.3 选定架构
- 主路:宽带 CT,Fair-Rite #43/#61 铁氧体磁芯 + 定制多匝绕组
- 辅路:电容耦合,补足 >500 MHz 段
- 目标指标:-3 dB 带宽 1 MHz – 1 GHz,插损 <10 dB

### §2.4 保护与工频隔离链
- GDT(气体放电管)一级浪涌
- MOV(压敏电阻)钳位
- 共模扼流圈(>100 MHz 阻抗 >1 kΩ)
- TVS 阵列处理快脉冲
- 高压隔直陶瓷电容
- LC 高通(截止 ≥1 MHz, 50 Hz 抑制 >80 dB)

### §2.5 已知风险
- 铁氧体磁导率在 >500 MHz 段下降 → 可能需要复合磁芯或电容耦合补足
- 电源线传导损耗在测之前未知

**篇幅**:2–3 页。**Figure 2**(耦合 + 保护原理图)。

---

## Ch3 — 模拟前端设计(2 页)

### §3.1 架构
- 单级或两级级联 LNA:总增益 30–40 dB,NF <3 dB,100 MHz – 1 GHz 平坦
- 基线方案:Mini-Circuits PGA-103+(22 dB) 级联 ZX60-P103LN+(后级)
- 论文参考:EM Eye 用 Foresight FST-RFAMP06 单级 40 dB;我方提出可替代方案

### §3.2 链路预算表

**Table 2**(必须):

| 节点 | 信号电平 | 噪底 | 累计增益 | 累计 NF |
|---|---|---|---|---|
| 耦合器输入 | −80 dBm | −120 dBm/Hz | 0 dB | — |
| 耦合器输出 | −85 dBm | … | −5 dB | 5 dB |
| LNA 输出 | −45 dBm | −90 dBm/Hz | 35 dB | ~3 dB |
| SDR ADC 输入 | … | … | … | … |

(数字为示意,Day 1-2 用 EM Eye 测得的近场 SNR 细化。)

### §3.3 可选可切换 BPF 组
- 引用 EM Eye Appendix F 指出 BPF 是 SNR 改进方向
- 三段 SAW(100–300 / 300–600 / 600–1000 MHz)+ PE42423 RF 开关切换
- 备注:BPF 是增强项,基线靠 SDR 数字下变频获得选频性

### §3.4 PCB 与屏蔽
- 4 层板叠层;RF 路径用 Rogers RO4350B
- LNA 单独腔体加铜罩
- 星形接地,模拟/数字域隔离

**篇幅**:2 页。**Figure 3**(LNA 模块原理图 + PCB 草图)。

---

## Ch4 — 数据采集与无线传输(2 页)

### §4.1 SDR 选型
- **选定:ADALM-Pluto**(AD9363/AD9364 + Zynq xc7z010)
- 理由:解锁后 70 MHz – 6 GHz, 12-bit IQ, 56 MHz 瞬时 BW(远高于 EM Eye 8 MHz 基线)
- **关键差异化**:候选人有该平台(Zynq xc7z010, Pluto)的 OFDM+LDPC 收发机完整 HDL 实战经验,BER=0 板级验证 → 具备扩展 Pluto 固件做 FPGA 侧预处理的能力
- 备选:LimeSDR Mini 2.0

### §4.2 采样策略
- 对齐 EM Eye 基线:fs = 8 MHz IQ,中心频率锁定在 MIPI byte-clock 谐波
- 引用 EM Eye Table II 的频点预设(12 COTS 设备)
- 频点跟踪算法:开机扫描 100 MHz – 1 GHz,锁定最强 30 Hz 周期性载波,±50 ppm 漂移补偿

### §4.3 传输方案决策 — 原始 IQ vs 板上重建

**Table 3**(必须):

| 方案 | 无线 BW | 上位机算力 | 算法灵活性 | 延迟 |
|---|---|---|---|---|
| WiFi 6 传原始 IQ | 192 Mbps | 高 | 最大 | 高 |
| 板上幅度解调+重建,传图像 | <30 Mbps | 低 | 设计时锁定 | 低 |

- **选定**:v1 原始 IQ 直传(便于复现论文管线,算法迭代灵活);v2 板上加速作为路线图

### §4.4 无线模块
- **主选**:WiFi 6 (RTL8852BE 或 Intel AX210)
- 备选:蓝牙 5.0(仅用于板上重建后的图像流)

### §4.5 主控 SoC
- **选定**:Raspberry Pi CM4 Lite 8GB + WiFi 6
- 理由:ARM A72 四核,Linux + Python + GNURadio 生态成熟,候选人有 RK35xx + Ubuntu 部署经验
- Pluto 通过 USB OTG 接 CM4

### §4.6 Sidebar — 板上加速路线图(差异化亮点)
- 利用 Pluto 内置 Zynq-7010 PL 实现 |I+jQ| 幅度解调 + 30 Hz 自相关帧同步
- 输出 8-bit 解调流(~30 Mbps),替代 12-bit 原始 IQ(192 Mbps)
- 释放 CM4 算力做更高层重建
- **可行性论证**:候选人对该 Pluto Zynq 内部 HDL 修改 + Zynq UltraScale+ HLS CNN 部署均有直接经验

**篇幅**:2 页。**Figure 4**(数字子系统框图)。

---

## Ch5 — 主要器件选型(1–2 页)

**Table 4**(完整 BOM,必含):

| 模块 | 主选 | 替代 | 理由 |
|---|---|---|---|
| 耦合 | Fair-Rite 2643000201 + 定制绕组 | Pearson 411(商品) | 体积 vs 性能 |
| 保护 (GDT) | Bourns 2026-23-SM | EPCOS B88069X | 工业级标准 |
| 保护 (TVS) | SMAJ12A | TPSMB18A | 快速响应 |
| 共模扼流 | Würth 744232222 | Coilcraft CMTI | 高频段阻抗 |
| LNA 一级 | Mini-Circuits PGA-103+ | PSA4-5043+ | EM Eye 论文风格的 40 dB 链路 |
| LNA 二级 | Mini-Circuits ZX60-P103LN+ | — | 后级 |
| BPF 开关(可选) | Peregrine PE42423 | ADRF5040 | 高隔离 RF 开关 |
| SDR | ADALM-Pluto SOM | LimeSDR Mini 2.0 | 候选人前期平台 |
| 主控 SoC | Raspberry Pi CM4 8GB Lite WiFi | NVIDIA Jetson Nano | 成本 + Linux 成熟度 |
| 无线 | RTL8852BE 内置 WiFi 6 | 外置 AX210 | 集成度 |
| AC-DC 隔离 | Mean Well IRM-10-5 | Recom RAC03 | EMC + 安规 |
| LDO(模拟) | TI TPS7A47 | LT3045 | 超低噪声 |
| 开关电源(数字) | TI TPS54320 | LM5085 | 通用大电流 |
| 外壳 | 3D 打印 ABS 或 CNC 铝合金 | — | Phase-1 原型 |

**篇幅**:1–2 页。

---

## Ch6 — 整体成本估算(1 页)

### BOM 成本(Route A 单台原型)

| 类别 | 成本 (CNY) |
|---|---|
| 耦合 + 保护 | 130 |
| 滤波开关(可选) | 200 |
| LNA 模块 | 250 |
| SDR (ADALM-Pluto SOM) | 1500 |
| 主控 (Raspberry Pi CM4 + 载板) | 1000 |
| 电源 | 120 |
| PCB(4 层小批量,含贴片) | 800 |
| 外壳 + 连接器 | 350 |
| **BOM 合计** | **~ 4350** |

### NRE 成本

| 项 | 成本 (CNY) |
|---|---|
| PCB 打样(2 次迭代) | 1500 |
| 3D 外壳(2 次迭代) | 800 |
| 测试设备时间(VNA、频谱仪租用) | 3000 |
| **NRE 合计** | **~ 5300** |

### 工时

- 1 RA × 6 个月全职
- Phase 0(可行性):3 周
- Phase 1(工程原型):3 个月
- Phase 2(集成 + 验证):2 个月

### 分阶段交付
- **Phase 0**(3 周):在现成器材上复现 EM Eye on RPi V1,并用 LISN 验证电源线传导 — Go/No-Go 决策门
- **Phase 1**(3 个月):耦合网络、模拟前端、集成原型
- **Phase 2**(2 个月):板上加速、多设备验证、终版报告

**篇幅**:1 页。

---

## §7 风险与未决问题(½ 页)

诚实+具体。审稿人欣赏坦诚,远胜过分自信。

- 电源线在 100 MHz – 1 GHz 段的传导损耗未知,实测前估计 40–60 dB,>60 dB 可能拖垮 SNR
- 铁氧体磁芯 CT 在 >500 MHz 未必能撑住带宽,可能需复合磁材
- COTS 设备差异:EM Eye Table II 的 12 台设备未必每台都在电源线上有同等强度泄漏
- 法规:市电耦合涉及 EMC Class B + IEC 61010 安全要求
- ADALM-Pluto 供应偶尔受限

---

## Annex A — 候选人相关经验(1 页)

| 项目 | 硬件平台 | 关键结果 | 仓库 |
|---|---|---|---|
| OFDM + LDPC PlutoSDR 收发机 | Zynq xc7z010 (Pluto) | 完整 HDL 链路,BER = 0 板级 | private |
| XCZU3EG PL 车牌识别 CNN | Zynq UltraScale+ | 87.94 % / 675 ms 端到端 PL 侧 | github.com/stongry/FPGA-ZYNQ |
| RK3568 Ubuntu 移植 + RKNN NPU 部署 | Rockchip + NPU | 生产级嵌入式 Linux + 边缘 AI | private |
| EC800M 语音 AI 模块 | Quectel 蜂窝模块 | 完整无线集成 | private |
| 智能家居 Slint UI 移植 | RK3588 面板 | 62.97 fps(面板上限) | private |

每行 1 句话,数字说话。

**这一节为什么重要**:本设备的每一层(Pluto-Zynq 上的 HDL、FPGA 加速、ARM SoC 上的嵌入式 Linux、无线集成、整机集成)都对应着候选人已经出货过的项目。

---

## 提交细节

- 最终格式:PDF,单栏,11–12pt,A4
- 篇幅:7–10 页(含 Annex 不超过 15 页)
- 文件名:`PowerLineSideChannel_Proposal_[姓名]_2026-05.pdf`
- 邮件回复 Yan,CC 闫浩然(如适用),3 句正文 + 附件
- 在邮件里提一句:"a private GitHub repo for source tracking is available if useful for review" — 这本身是工程素养的展示
