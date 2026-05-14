# 电源线侧信道采集设备 — 设计提案(主体)

**项目**:Power-Line Side-Channel Acquisition Device
**副标题**:将 EM Eye 攻击从空中电磁辐射延伸至电源线传导泄漏
**目标单位**:University of Michigan, Yan Long Lab
**版本**:v1.0 主体稿(Ch1–Ch6)
**日期**:2026-05-14

---

## 摘要

本提案描述一款便携式电源线侧信道采集设备的工程方案,用于把 Long 等 (NDSS 2024) 提出的 EM Eye 摄像头攻击从空中电磁辐射通道延伸至**电源线传导通道**。设备形态采用 **Route A 便携集成式**(目标尺寸 150 × 80 × 50 mm,可压缩到 100 × 60 × 30 mm),通过商用宽带电流互感器(Tekbox TBCP2-1000,100 kHz – 1 GHz)夹住被测设备(DUT)电源线进行磁耦合采样,后接候选人自研的 ERA-4SM+ × 2 级联 LNA(VNA 实测 +28 dB @ 100 MHz)、LC 高通滤波器,最终送入候选人手头的 LDSDR 7010 rev2.1 SDR(AD9363 + Zynq-7010,2T2R,千兆以太网)。整机由 USB-C 5 V 供电,**与市电完全电气隔离**(唯一与市电"耦合"的元件是磁芯式 CT)。

设备的工程价值与候选人差异化能力对应如下:

- **形态**:Route A 便携集成,Phase 2 演进至插头适配式
- **耦合**:主路 Tekbox 商用宽带 CT(Phase 0 即可投入),辅路 HV 陶瓷电容覆盖 >500 MHz
- **采集**:LDSDR 7010 千兆以太网直传双通道 IQ,板内 Zynq-7010 PS 直接出网,不外接主控
- **差异化**:候选人在 PlutoSDR 同款 Zynq-7010 上有完整 OFDM + LDPC HDL 链路 BER=0 板级验证经验,可直接迁移到 emeye_accel(板上 |I+jQ| + 30 Hz 自相关帧同步)加速模块
- **分阶段交付**:Phase 0(3 周可行性 Go/No-Go)→ Phase 1(3 个月工程原型)→ Phase 2(2 个月集成验证 + 板上加速)

本主体稿覆盖 Ch1–Ch6,候选人前期已完成的具体工作详见独立的"Pre-Phase 0 已完成工作"章节(由另一份文档承载),本文档在相关位置引用。

---

# 第一章 总体形态、尺寸与系统框图

## §1.1 形态决策:Route A vs Route B

功能需求书规定设备最大尺寸 ≤ 150 × 80 × 50 mm,并暗示了两种可行的物理形态。本提案在 Day 1 阶段已锁定 **Route A 便携集成式**为 Phase 1 主交付形态,Route B 插头适配式作为 Phase 2 演进方向。决策依据见表 1.1。

**表 1.1  形态对比**

| 维度 | Route A 便携集成式(选定 Phase 1) | Route B 插头适配式(Phase 2) |
|---|---|---|
| 供电方式 | USB-C 5 V(移动电源 / 笔记本 / 充电器) | 内含 AC-DC,直插市电 |
| 与市电关系 | **电气完全隔离**(仅 CT 磁耦合) | 直接接触 220 V |
| 触电风险 | 归零 | 高,需 IEC 61010 + EMC Class B 认证 |
| 保护链复杂度 | TVS + DC 隔直 + LC HPF(¥11) | 全套 GDT/MOV/共模扼流/TVS(¥80+) |
| BOM 净成本(单台) | ~ ¥820 | ~ ¥1300+ |
| 现场部署 | 充电宝、车载 USB、笔记本均可供电 | 仅墙插场景 |
| 隐蔽性 | 中(可伪装插线板上的小盒) | 高(完全嵌入墙插) |
| 开发周期(原型) | 3 周 Phase 0 + 12 周 Phase 1 | + 4 周安规认证准备 |
| 风险 | 低 | 中高(安规认证不确定性) |

**选 Route A 的核心理由**:
1. **安全性**:RA 提案阶段不应让候选人承担市电直接接触的设计责任,Route A 的整机与市电零电气连接,触电风险归零。
2. **快速交付**:Phase 1 三个月可出可用原型,Phase 2 再演进到插头形态。
3. **形态自由**:USB 供电 → 不绑死场景,实验室桌面 / 现场便携两个场景都覆盖。

## §1.2 尺寸预算

外壳目标 100 × 60 × 30 mm(留 50% 边距,极限可压到 80 × 50 × 25 mm),内部子模块布局如表 1.2。

**表 1.2  Route A 内部尺寸分配**

| 模块 | 占用尺寸(mm) | 占用比例 | 备注 |
|---|---|---|---|
| 模拟前端板(CT 二次侧 → LNA 输出) | 80 × 60 × 8 | 35 % | 4 层 PCB,RF 路径 Rogers RO4350B,LNA 单独铜罩屏蔽腔 |
| LDSDR 7010 rev2.1 SOM | 90 × 50 × 12 | 38 % | 候选人 BYO,标准 Pluto 衍生板形态 |
| USB-C 入口 + ESD 保护 + 5 V LDO(TPS7A47)| 30 × 20 × 6 | 5 % | 模拟域净化电源 |
| Tekbox TBCP2-1000 CT(夹式外置) | OD ≈ 100,外挂 | — | 通过短同轴接入,**不进主壳内** |
| Ethernet 输出口 RJ45 | 16 × 13 × 6 | 4 % | 千兆 → PC |
| 散热与屏蔽间隙 | — | 18 % | 顶/底盖空隙 + EMI 衬垫 |

**关键说明**:Tekbox CT 因外径 100 mm,**不放入主壳内**,而是通过 RG-316 短同轴(< 30 cm)接入主壳的 SMA 输入。Phase 2 演进时(自研小型化 CT 完成)再考虑 CT 一体化集成,目标把 100 mm 压缩到 ≤ 20 mm。

## §1.3 系统总框图

完整系统由 7 个功能模块串联组成,见图 1.1(占位:`figures/proposal_block_diagram.png`)。

**图 1.1 文字描述**(参考下方 ASCII 草图,Day 2 将转 SVG):

```
+---------+   +---------+   +---------+   +---------+   +-----------+   +-------+   +-----+
| 被测    |---|  Tekbox |---|  TVS +  |---| LC HPF  |---| ERA-4SM+  |---| LDSDR |---| PC  |
| DUT     |   |  TBCP2  |   | DC 隔直 |   | fc=30M  |   |  × 2 LNA  |   |  7010 |   | 笔记本|
| 220V CN |   | 宽带 CT |   |         |   |         |   |  +28 dB   |   | AD9363|   | GbE |
+---------+   +---------+   +---------+   +---------+   +-----------+   +-------+   +-----+
   电源线         耦合          保护         滤波           放大          采集       传输
   (L+N同向       (100kHz       (低 C TVS    (4 阶 Bw    (BYO,VNA    (双 RX     (千兆
    穿芯)         -1GHz)        + 1nF NP0)   50Ω)       实测平坦)    +千兆Eth)   以太网)
                                                                       Zynq-7010
                                                                       PS Linux
```

7 个核心模块:
1. **耦合**:Tekbox TBCP2-1000 商用宽带 CT,L+N 同向穿芯测共模电流,DM 抑制估计 30–40 dB
2. **保护**:Bourns CDSOT23-T05LC 低 C TVS(C < 1 pF @ 1 GHz)+ Murata NP0 1 nF DC 隔直
3. **滤波**:LC 4 阶 Butterworth HPF,fc = 30 MHz,通带损耗 < 1 dB,50 Hz 衰减 > 100 dB
4. **放大**:候选人 BYO ERA-4SM+ × 2 级联 LNA,**VNA 实测 +28 dB @ 100 MHz**,5.6 MHz – 3 GHz 平坦 ± 3 dB(已完成,详见"Pre-Phase 0 已完成工作"章节)
5. **采集**:LDSDR 7010 rev2.1(候选人 BYO),AD9363 解锁到 AD9361 频率范围 70 MHz – 6 GHz,12-bit IQ,2 RX 并行,28 dB 内部增益可调
6. **主控**:**直接用 LDSDR 板内 Zynq-7010 PS**(Cortex-A9 + Linux + iio_attr),不外接 RPi CM4
7. **传输**:千兆以太网原始 IQ 直传,Phase 2 演进为板上 emeye_accel 加速 + 8-bit 解调流

## §1.4 Phase 2 向插头形态演进路线

Route B 是终态隐蔽攻击形态,但 Phase 1 不强求。Phase 2(Week 17–24)集成阶段如果时间允许,演进路径如下:

| 步骤 | 工作内容 | 预计工时 |
|---|---|---|
| (1) | 设计内部 AC-DC(Mean Well IRM-10-5,5 V/2 W),替代 USB 输入 | 2 周 |
| (2) | 补全市电保护链(GDT + MOV + 共模扼流圈) | 1 周 |
| (3) | 自研小型化 CT(Fair-Rite #43+#61 复合磁芯,5 匝绕组),压到 OD ≤ 20 mm,集成进壳内 | 3 周 |
| (4) | 6 层 PCB 重新布板,IEC 61010 间距规则,加铜罩屏蔽 | 2 周 |
| (5) | EMC Class B 预测试(扫频远场 + 传导 EMI) | 1 周 |

Phase 2 总工时约 9 周,在 8 周(Week 17–24)预算内紧凑可行。**Phase 2 是工程加分项,不是 Phase 1 的硬交付**。

---

# 第二章 电源线高频泄漏耦合与提取 ⭐ 关键章节

本章是整份提案的技术心脏。审稿人(EM Eye 论文作者团队)主要靠这一章判断候选人对侧信道电磁物理的理解深度。

## §2.1 物理机制

### §2.1.1 CMOS + MIPI 总线产生共模电流的物理过程

EM Eye 论文 §III 明确指出:*"在嵌入式视觉系统中,图像传感器与 ISP 之间的 MIPI CSI-2 串行链路传输 sub-ns 边沿的高速数据,这些数据信号天然耦合到外围金属结构,使得连接电缆本身成为非预期发射天线 (unintentional transmission antenna)"*。

物理机制可分为三阶段:

1. **源**:MIPI CSI-2 D-PHY 物理层以 byte clock(RPi V1 为 51 MHz × 4 倍 = 204 MHz 单 lane 速率)切换驱动差分对。每次比特跳变产生 dV/dt ~ 1 V/ns 的电压沿,通过共模电感(数据线对参考地)耦合产生**共模电流分量**。
2. **传播**:共模电流沿数据线 → 进入主板地参考 → 通过 PCB 寄生电容 / 直接走线传导到电源输入端 → 经稳压模块的寄生回路渗透到外部电源线(L + N + PE)。
3. **泄漏频段**:由于驱动信号本身是 byte clock 谐波富集,泄漏在频谱上呈现强谐波线条,典型 100 MHz – 1 GHz 段,与论文 Table II 测得的 12 款 COTS 设备(155 MHz – 1740 MHz)一致。

### §2.1.2 电源线作为"非预期传输天线"的延伸

EM Eye 原论文使用近场磁探头(Beehive 100C)或 LPDA 远场天线在**空气**中拾取这些泄漏。我们提出的扩展:**对同一源信号,共模电流也会沿电源线传导出来**,因为:

- 电源线本身在 100 MHz – 1 GHz 段电气长度已远大于 1/4 波长(0.5 m 线在 500 MHz 处 ≈ 0.83 λ),表现为分布参数传输线
- 共模电流不会被电源滤波器有效抑制(电源滤波器是为 EMC Class B 设计的传导骚扰抑制,典型工作到 30 MHz 即截止)
- 在 100 MHz 以上,设备内部的 X1/Y2 安全电容失去作用(寄生电感主导),共模电流可以"穿过"电源进入外部电源线

数量级估算(详细推导见 `theoretical_derivations.md` §1–3):

| 参数 | 数值 | 推导依据 |
|---|---|---|
| RPi V1 MIPI byte clock | 51 MHz | 论文 Table II |
| 主泄漏频点(204 MHz / 255 MHz) | byte clock 的 4 倍 / 5 倍谐波 | 论文 Table II |
| 估算 CM 电流 $I_\mathrm{CM}$ | 1–10 μA(待 PhD 校准) | 类比空气场强 -80 dBm + 寄生电感模型 |
| Tekbox CT 二次侧电压 | $V_2 = Z_T \cdot I_\mathrm{CM} = 5\,\Omega \times I_\mathrm{CM}$ | $Z_T$ = 5 Ω 平均(Tekbox 数据手册) |
| 等效功率 @ 50 Ω | $P = V_2^2/50 = -77 \sim -57\,\mathrm{dBm}$ | 假设 $I_\mathrm{CM}$ ∈ [1, 10] μA |

**关键不确定性**:$I_\mathrm{CM}$ 的绝对值是 Phase 0 必须实测验证的核心数字,也是要向 PhD 闫浩然学长**优先求证**的问题(已列入 P1 优先级问询清单)。

## §2.2 耦合方式权衡

本节给出三种候选耦合方式的完整对比,并说明为什么选用"主路宽带 CT + 辅路 HV 电容耦合"双通道架构。

**表 2.1  耦合方式权衡(5 列完整对比)**

| 方式 | 频响 | 工频隔离 | 体积 | 安全性 | 选择 |
|---|---|---|---|---|---|
| **宽带 CT(Tekbox TBCP2-1000)** | 100 kHz – 1 GHz, 平坦 ± 2 dB | 优(磁耦合,电气完全隔离) | OD ≈ 100 mm(夹式) | 高 | **主路** |
| **HV 陶瓷电容耦合(1 kV / 4.7 pF / NP0)** | 100 MHz – 数 GHz(> 500 MHz 优势)| 差(电容短路风险,需双重串联 + LC HPF 保护) | 0805 SMD,极紧凑 | 中(失效模式为短路) | **辅路** |
| 微型 LISN(Tekbox TBL5016-1 类) | 9 kHz – 30 MHz 标准 | 自带(LISN 定义就是隔离 + 阻抗稳定)| 大(150 × 100 × 80 mm) | 标准 EMC | **否决**(频段不够 + 体积超标) |

**选择理由**:
1. **主路 Tekbox CT 解决 80% 问题**:100 kHz – 1 GHz 平坦覆盖 EM Eye Table II 12/12 设备的全部主泄漏频点,NIST 可追溯校准,Phase 0 第 1 周即可投入。
2. **辅路 HV 电容补足 >500 MHz**:CT 在 500 MHz 以上磁芯磁导率开始下降,而 HV 陶瓷电容(典型 4.7 pF / 1 kV NP0)在 500 MHz – 2 GHz 段呈现低阻抗、低损耗,正好接力。LDSDR 2 RX 通道允许双路同时采样、PC 端融合。
3. **否决 LISN**:虽然是 EMC 国标方法,但典型 LISN 上限 30 MHz(覆盖工业骚扰),我们目标频段下限就是 100 MHz,频段完全错开。即使有 30 – 200 MHz 拓展型 LISN,体积也远超我们的 150 × 80 × 50 mm 预算。

## §2.3 选定架构

**主路(CT)**:
- 型号:Tekbox TBCP2-1000 商用宽带电流探头
- 频段:100 kHz – 1 GHz,平坦 ± 2 dB
- 转移阻抗:$Z_T \approx 5\,\Omega$(等效插损 $S_{21} = 20\log(Z_T/R_\mathrm{source}) = -20\,\mathrm{dB}$ 平台)
- 一次侧最大通过电流:30 A AC(远大于任何 DUT 工作电流)
- **穿芯方式**:**L + N 同向穿芯**,PE 独立走线在 CT 之外
  - 物理推导(见 `theoretical_derivations.md` §2):磁通 $\Phi_\mathrm{CT} \propto I_L + I_N = 2 I_\mathrm{CM}$,差模电流 $I_\mathrm{DM} = (I_L - I_N)/2$ 完全抵消,共模电流加倍叠加
  - 实际 DM 抑制经验估计:$\mathrm{DM\_Rej} \approx 20\log(D_\mathrm{window}/\delta_\mathrm{offset}) + \mathrm{other} \approx 30{-}40\,\mathrm{dB}$
- 工装:被雇佣后 Week 1 制作 **2 芯延长线工装**,机械保证 L+N 几何对齐,$\delta_\mathrm{offset} \leq 0.5\,\mathrm{mm}$

**辅路(HV 电容)**:
- 元件:Murata GA355DR7GF472KY02 (4.7 pF / 1 kV NP0) × 2 串联(双重失效保护)
- 接入点:DUT 电源线 L 线对地,经 LC HPF(fc = 200 MHz)+ 50 Ω 端接 → SMA → LDSDR RX2
- 频段:200 MHz – 2 GHz,补足 CT 高频段
- 安全:即使一颗电容击穿短路,另一颗仍保持 > 500 V 工作电压余量;Phase 1 进一步加 GDT 一级浪涌防护到 LDSDR 输入

**双路融合策略**(LDSDR 2T2R 同时采样):
- LDSDR RX1 → CT 主路 → LO 锁 RPi V1 @ 204 MHz(byte clock 4 次谐波)
- LDSDR RX2 → HV 电容辅路 → LO 锁 @ 1.485 GHz(若做 HDMI 扩展)或 900 MHz(EM Eye Table II 中段)
- PC 端按 EM Eye 论文 Eq.3 做相干合成,SNR 提升估算 +3 dB(双路独立噪声平均)

**与论文原方案的差异化**:论文用单 USRP **时分**采样不同频段;我们用 LDSDR 2 RX **同时**采样,这是 v1 baseline 就具备的硬件优势,而非 v2 路线图。

## §2.4 保护与工频隔离链

完整保护链如图 2.1 文字描述(占位:`figures/proposal_protection_chain.png`)。

```
[Tekbox CT 二次侧 BNC 输出 50Ω]
        |
        | RG-316 短同轴(< 20 cm)
        v
[SMA 母座 PCB 入口] ── 单点接地(铜罩 → PCB 模拟地)
        |
        v
[低 C TVS:Bourns CDSOT23-T05LC]    <-- ESD/瞬态钳位,C < 1 pF @ 1 GHz
   - V_RWM = ±5 V,V_C @ 1 A = ±8 V
   - 响应 < 1 ns,ESD 容忍 ±15 kV(IEC 61000-4-2 4 级)
        |
        v
[DC 隔直:Murata GRM18 NP0 1 nF / 100 V]    <-- 阻 DC,通 RF
   - 50 Hz 容抗 3.18 MΩ(完全阻断)
   - 30 MHz 容抗 5.3 Ω(-0.4 dB 损耗,可忽略)
   - 1 GHz 容抗 0.16 Ω(完全透明)
        |
        v
[LC HPF Stage 1:4 阶 Butterworth 50Ω,fc = 30 MHz]
   C1 = 150 pF NP0
   L2 = 150 nH Coilcraft 0603HP(Q > 50 @ 100 MHz)
   C3 = 56 pF NP0
   L4 = 330 nH Coilcraft 0603HP
   - 50 Hz 衰减 > 100 dB(实测目标,理论 -462 dB)
   - 通带 30 MHz – 3 GHz 损耗 < 1 dB
        |
        v
[LNA 输入端,接 ERA-4SM+ × 2 级联板]
```

**Phase 2(Route B 演进)新增市电入口保护**:GDT(Bourns 2026-23-SM)→ MOV(Littelfuse V275LA20A)→ 共模扼流圈(Würth 744232222),用于内含 AC-DC 的插头形态。Phase 1 用 USB 供电时,这些元件全部不需要(详见 §1.1 形态决策)。

**关键工程规则**:
1. **信号路径绝对不加共模扼流圈**:本设备的"目标信号"就是共模电流本体,信号侧加共模扼流圈等于扼掉信号。这是初学者最容易踩的坑,我们在 Day 1 已经识别(见 `ch2_design_deep_dive.md` §4.1 警告)。
2. **TVS 选低 C 型号**:普通 TVS(如 SMAJ12A)寄生电容 ~ 200 pF,在 1 GHz 时容抗仅 0.8 Ω,几乎将信号短路到地;必须用 C < 1 pF 的 RF 专用 TVS(Bourns CDSOT23-T05LC,$C < 1\,\mathrm{pF}\,@\,1\,\mathrm{GHz}$,等效阻抗 160 Ω,RF 透明)。
3. **隔直电容选 NP0/C0G 介质**:NP0 温度系数 ±30 ppm/°C,Q 值高,无压电效应;若用 X7R 介质,机械振动会产生附加噪声,在 μV 级信号上不可接受。

## §2.5 已知风险与缓解措施

**表 2.2  Ch2 风险清单**

| 风险编号 | 描述 | 触发条件 | 影响 | 缓解措施 | 优先级 |
|---|---|---|---|---|---|
| R2-1 | 实际 $I_\mathrm{CM}$ 比假设的 1 μA 弱 10 dB | Phase 0 实测信号 < -100 dBm 到 LNA 输入 | 链路余量不够,需加第三级 LNA | Phase 1 预留 PGA-103+ 第三级(+22 dB)位置,BOM 备料 | 🔴 高 |
| R2-2 | Tekbox CT > 500 MHz 段实际衰减大于数据手册 | VNA 实测平坦度 > ± 5 dB | 高频段 SNR 下降 | 启用辅路 HV 电容补足 + 多频段融合软件补偿 | 🟡 中 |
| R2-3 | L+N 工装机械精度不足,DM 抑制 < 20 dB | Phase 0 实测 50 Hz 残留 > -40 dBm 到 LNA 输入 | LNA 饱和 | 改用 3D 打印高精度工装,$\delta_\mathrm{offset} \leq 0.2\,\mathrm{mm}$ | 🟡 中 |
| R2-4 | 电源线驻波导致 CT 位置敏感(0.5 m 线在 GHz 段非准静态) | 同一 DUT 在不同墙插测试结果 SNR 差 ± 10 dB | 测试不可复现 | 统一工装距离(墙插 → DUT 固定 1.5 m),并记录位置 | 🟢 低 |
| R2-5 | HV 电容辅路击穿短路 | DUT 浪涌 / 雷击 | LDSDR 损坏 | 双电容串联 + Phase 1 加 GDT 一级浪涌防护 | 🟢 低 |
| R2-6 | 不同 DUT 的 CM 阻抗差异大(20–500 Ω),$I_\mathrm{CM}$ 量级差 20 dB | 多设备对比时部分设备测不到 | 部分场景失败 | LDSDR 内部 AGC 76 dB 范围 + 软件自动增益调度 | 🟢 低 |

## §2.6 Phase 0 实测 Go/No-Go 决策门

被雇佣后 Week 1–3 内完成下列 5 项实验,作为是否进入 Phase 1 的硬决策门。

**实验流程**:

1. **Week 1**:Tekbox CT 到货 → 配合实验室公共 VNA + 频谱仪验证 CT S21 频响,扫频 100 kHz – 1.5 GHz,要求 100 kHz – 1 GHz 平坦 ± 3 dB
2. **Week 1**:候选人 BYO ERA-4SM+ × 2 LNA 与 LDSDR 集成调试,iio_attr 控制 AD9363 LO + 增益,验证整链注入校准(信号发生器 -80 dBm → LDSDR 接收 RSSI -20 dBm,匹配 +60 dB 增益)
3. **Week 2**:RPi 4B + Camera Module V1.3 通电(论文同款 DUT),Tekbox 夹电源线,频谱仪扫 50 MHz – 1 GHz,搜索 30 Hz 周期性载波,**目标频点 204 MHz / 255 MHz**(论文 Table II)
4. **Week 2–3**:LDSDR 8 MSPS IQ 采集,Python 端做幅度解调 + 30 Hz 自相关 → Tf / Tr 估计 → 像素重排
5. **Week 3**:扩展到 3 个 COTS 设备(Wyze Cam Pan 2 / Xiaomi Dafang / 360 行车记录仪),重复 (3)(4)

**Go 条件**(任一满足即可推进 Phase 1):
- (a) RPi V1 在 204 MHz 测到 SNR > 15 dB 的 30 Hz 周期信号,Python 重建结果 SSIM > 0.5
- (b) 至少 2 个 COTS 设备在 EM Eye Table II 列出的频点测到 SNR > 10 dB

**No-Go 条件**(出现任一立即停止):
- (a) 所有 5 个 DUT 在全部目标频点均测不到 SNR > 5 dB 的信号(说明电源线传导通道不存在或损耗 > 60 dB)
- (b) LNA 在工作状态下饱和,无法通过 BPF 解决(说明带外干扰过强)

**预算前置门**:Phase 0 总预算 ¥ 8,860,即使 No-Go 项目总投入 < ¥ 10,000,无沉没成本风险。这一段写法是给 PI 的"good engineering judgment"信号。

---

# 第三章 模拟前端设计

## §3.1 架构:候选人 BYO 的 ERA-4SM+ × 2 级联

**关键事实**:候选人在加入项目之前**已经完成** ERA-4SM+ × 2 级联 LNA 模块的设计、加工与 VNA 实测验证。详见"Pre-Phase 0 已完成工作"章节的 LNA 测试报告。本提案的模拟前端直接复用该模块,**不需要额外开发**。

**实测数据摘要**(详见 `figures/lna_era4sm_x2_gain.PNG` 和 `lna_era4sm_x2_off.PNG`):

| 参数 | 实测值 | 备注 |
|---|---|---|
| 工作频段 | 5.6 MHz – 3 GHz | 覆盖 EM Eye Table II 12/12 设备 + HDMI 主谐波 |
| 平均增益 | +28 dB @ 100 MHz | VNA 实测,网络分析仪标定后 |
| 增益平坦度 | ± 3 dB @ 100 MHz – 1 GHz | 在 RF 链路预算中视为常数 |
| 噪声系数(数据手册典型值)| 2.5 dB 单级 / ~ 3.5 dB 级联 | 实测 NF 待 Phase 0 用噪声源标定 |
| P1dB(输出端)| +18 dBm 单级 / +15 dBm 级联(估算) | 留 IIP3 余量给电源线场景强干扰 |
| 隔离度(失电状态) | > 50 dB | 实测,LNA 关电时不会串通 |
| 供电 | 5 V @ 60 mA(单级)| 整体 120 mA,USB-C 可直供 |
| 物理尺寸 | 50 × 30 × 12 mm | 含 SMA + 屏蔽腔 + 偏置电路 |

**论文对标**:EM Eye 论文 Appendix H 使用 Foresight FST-RFAMP06(40 dB, 单级),候选人 ERA-4SM+ × 2 = 28 dB,**差 12 dB 增益**。这 12 dB 差距由 LDSDR AD9363 内部 LNA + IF VGA(最高 30 dB)弥补,且 AD9363 内部级联点在 LNA 之后,**对系统 NF 影响 < 0.1 dB**(Friis 公式 NF_total ≈ NF_LNA1,后级 NF 被前级增益除去)。

## §3.2 链路预算表

按目标频段 200 MHz、假设 $I_\mathrm{CM} = 1\,\mu A$ 推导(完整推导见 `theoretical_derivations.md` §3),关键节点见表 3.1。

**表 3.1  链路预算(节点级)**

| 节点 | 信号电平 (dBm) | 噪底 (dBm/Hz) | 累计增益 (dB) | 累计 NF (dB) | 备注 |
|---|---|---|---|---|---|
| (1) DUT 一次侧 $I_\mathrm{CM}$ | $I_\mathrm{CM} = 1\,\mu A$ | — | — | — | 假设值,Phase 0 校准 |
| (2) Tekbox CT 二次侧输出 | -77 | -174 | -20 | 20 | $V_2 = 5\,\Omega \times 1\,\mu A = 5\,\mu V$,等效 -77 dBm @ 50 Ω |
| (3) TVS + DC 隔直 + 走线 | -77.5 | -174 | -20.5 | 20.5 | -0.5 dB 链路损耗 |
| (4) LC HPF Stage 1 输出 | -78 | -174 | -21 | 21 | 通带损耗 -0.5 dB |
| (5) ERA-4SM+ 第 1 级输出 | -64 | -171 | -7 | **3.5(主导)** | +14 dB, NF = 3.5 dB |
| (6) ERA-4SM+ 第 2 级输出 | -50 | -167 | +7 | 3.6(略升) | +14 dB,Friis 后级 NF 贡献 0.05 dB |
| (7) LDSDR AD9363 入口 | -50 | -167 | +7 | 3.6 | 含 SMA 同轴 -0.1 dB |
| (8) AD9363 内部 LNA(设最低增益 -3 dB)+ IF VGA(+30 dB)| -23 | -140 | +34 | 3.6 | IIP3 优先策略,扩动态范围 |
| (9) ADC 输入端 | -23 | -140 | +34 | 3.6 | 12-bit ADC 满量程 +10 dBm |
| (10) ADC 输出动态范围 | -33 dBFS | — | — | — | 信号离 ADC 饱和有 33 dB 余量 |

**关键公式**(Friis NF 级联,转线性):

$$
NF_\mathrm{total} = NF_1 + \frac{NF_2 - 1}{G_1} + \frac{NF_3 - 1}{G_1 \cdot G_2}
$$

代入 $NF_1 = 2.24, G_1 = 25.1, NF_2 = 2.24, G_2 = 25.1, NF_3 = 3.16$:

$$
NF_\mathrm{total} = 2.24 + \frac{1.24}{25.1} + \frac{2.16}{630.5} = 2.29 \Rightarrow 3.6\,\mathrm{dB}
$$

**热噪声底**(8 MSPS 工作带宽):

$$
P_\mathrm{noise} = kTB + NF = -174 + 10\log(8 \times 10^6) + 3.6 = -101.4\,\mathrm{dBm}
$$

**SNR 估算**:信号 -77 dBm 经 -20 dB CT → -97 dBm 等效到 LNA 输入,加 28 dB LNA → -69 dBm @ LDSDR 输入,噪底 -101 dBm 折算回 LDSDR 输入 ≈ -101 - 7 = -108 dBm,**SNR ≈ 39 dB**(舒适余量)。

如果实际 $I_\mathrm{CM}$ 弱 30 dB(0.03 μA),SNR 降到 9 dB,**仍勉强可重建**;若再弱 10 dB,需启用 Phase 1 备用 PGA-103+ 第三级(+22 dB)。

## §3.3 可切换 BPF 组(可选,Phase 1)

**Phase 0 实测后决定是否启用**。如果 Phase 0 测出:
- LNA 输出端在 100 MHz – 1 GHz 带外干扰功率 > -30 dBm(LNA 接近饱和)
- 目标频点 SNR < 10 dB(论文同等条件应有 ~ 30 dB)
- 重建图像有明显条纹干扰

则 Phase 1 启用 Stage 2 三段 SAW BPF + RF 开关切换。

**表 3.2  Stage 2 BPF 配置**

| 段 | 中心 (MHz) | 带宽 (MHz) | 推荐 SAW | 插损 (dB) | 阻带抑制 (dB) | 覆盖 EM Eye Table II 目标 |
|---|---|---|---|---|---|---|
| Band 1 | 200 | 150 – 250 | Murata SAFEB200MAF0F | 2.5 | 40 | RPi V1 (204), Xiaodu (204) |
| Band 2 | 450 | 350 – 550 | Murata SAFEA450MAA0F | 3.0 | 45 | Pixel 3 (515), 360 (450), Dafang (322 边缘) |
| Band 3 | 900 | 800 – 1000 | Murata SAFFB942MAA0F | 2.8 | 42 | WyzeCam (890), Dafang (890) |

**RF 开关**:Peregrine PE42423 SP4T,DC – 6 GHz,IL < 0.7 dB,隔离 > 50 dB,切换响应 < 1 μs。

**备注**:候选人在 XCZU3EG PL LPR CNN 项目中已有 PE42423 同类 SP4T RF 开关的 PCB 布板与 SPI 控制经验,Phase 1 集成无学习曲线。

**Stage 2 BOM**:¥ 350(3 SAW + 1 开关 + 偏置)。基线方案不启用,作为应急储备。

## §3.4 PCB 与屏蔽

**4 层 PCB 叠层**(80 × 60 mm 模拟前端板):

| 层 | 用途 | 材质 | 厚度 |
|---|---|---|---|
| L1 | RF 信号顶层(走线 + LNA + 滤波) | Rogers RO4350B(局部 RF 路径) + FR-4(数字偏置区域) | 0.508 mm(20 mil)|
| L2 | 完整接地平面(全填铜,绝对不切割) | FR-4 | 0.2 mm |
| L3 | 电源平面(分模拟 / 数字两区,星形互连) | FR-4 | 0.2 mm |
| L4 | 数字控制信号(I²C、SPI 偏置) | FR-4 | 0.508 mm |

**Rogers RO4350B 关键参数**:$\varepsilon_r = 3.66\,@\,1\,\mathrm{GHz}$,损耗角正切 0.0037。50 Ω 微带线宽 30 mil。

**屏蔽与接地策略**:
- 整个模拟前端板装铜罩(顶 + 底),罩接 L2 模拟地,**单点接地**到 LDSDR SOM 入口
- **LNA 单独子腔屏蔽**(铜罩内开间隔),与滤波 + 耦合区物理隔离,避免反馈振荡
- 模拟域与数字域接地通过单个 0 Ω 跳线(Star Ground),便于调试时分离测试
- SMA 接头采用 PCB 直焊式,接头外壳通孔到 L2 模拟地,via stitching 间距 ≤ 1/10 波长(@ 1 GHz 即 30 mm)

**电源去耦策略**:
- LNA 偏置 5 V → TI TPS7A47(超低噪声 LDO,4 nV/√Hz)→ 0.1 μF + 10 μF MLCC + 100 μF 钽电容近端布置
- LDSDR USB 5 V 输入 → TPS54320 开关电源(5 V → 1.8 V 数字)+ 独立 LDO 给 AD9363 RF 模拟电源

**预期 EMI 屏蔽效能**:铝合金外壳 + 铜罩 = 40 – 60 dB @ 1 GHz(覆盖 WiFi 2.4G / FM 广播 / GSM 900 等外部干扰源)。

---

# 第四章 数据采集与无线传输

## §4.1 SDR 选型:LDSDR 7010 rev2.1

**核心决策**:候选人 BYO 的 **LDSDR 7010 rev2.1** 取代原计划的 ADALM-Pluto,理由见表 4.1。

**表 4.1  LDSDR vs 标准 ADALM-Pluto 对比**

| 项 | LDSDR 7010 rev2.1(选定) | 标准 ADALM-Pluto | 差异 |
|---|---|---|---|
| 主芯片 | XC7Z010CLG400-2(Zynq-7010)| 同 | — |
| RF 收发器 | AD9363(解锁到 AD9361,70 MHz – 6 GHz) | 同 | — |
| DDR3 内存 | **512 MB** | 256 MB | **2 倍**,IQ 缓冲更大 |
| 网络接口 | **千兆 Ethernet + USB OTG** | 仅 USB 2.0 | **关键差异化**,解 USB 带宽瓶颈 |
| RF 端口 | **2 TX + 2 RX(2T2R)** | 1 TX + 1 RX | **双 RX 通道**,支持多频段并行 |
| 扩展 I/O | 38 pin PL + 8 pin PS | 极少 | 可控外部 BPF 切换开关 |
| 启动方式 | TF 卡 + 32 MB QSPI Flash | 内嵌 Flash | 调试方便,可拷板烧录 |
| 候选人持有 | ✅ BYO,已用作 OFDM + LDPC 完整项目 | 不持有 | **零启动成本** |

**关键差异化点**:候选人在 LDSDR 同款 Zynq-7010 上已经实现 OFDM + LDPC 完整 HDL 收发机链路,BER = 0 板级验证(详见"Pre-Phase 0 已完成工作"章节)。这意味着:

- LDSDR Buildroot rootfs(Linux 5.15)、iio_attr 用户态控制、Vivado 工程结构、AD9363 SPI 配置流程**全部已通**
- Phase 2 emeye_accel RTL(板上 |I+jQ| + 30 Hz 自相关)开发**直接复用** OFDM 项目的 AXI-Stream / AXI-Lite / IRQ 框架
- 候选人在 XCZU3EG HLS LPR CNN 项目的 87.94 % / 675 ms 端到端记录(github.com/stongry/FPGA-ZYNQ)同样适用于 LDSDR 板上 pix2pix 加速备份方案

## §4.2 采样策略

### §4.2.1 频点配置

对齐 EM Eye 论文基线 fs = 8 MSPS IQ,中心频率锁定在 MIPI byte clock 谐波。Phase 0 优先目标频点见表 4.2。

**表 4.2  Phase 0 主目标频点(EM Eye Table II 节选)**

| DUT | byte clock (MHz) | 目标 LO (MHz) | 论文 SSIM 参考 |
|---|---|---|---|
| Raspberry Pi V1(论文同款) | 51 | **204(4x)** / 255(5x) | 0.55 / 0.61 |
| Wyze Cam Pan 2 | 222.5 | **890(4x)** | 0.42 |
| Xiaomi Dafang | 80.5 | **322** / **890** | 0.39 |
| 360 行车记录仪 M320 | 112.5 | **450** | 0.37 |
| Google Pixel 3(对照)| 128.75 | **515** | 0.34 |

### §4.2.2 频点跟踪算法

**开机扫描**:Phase 1 完成后,设备开机时自动执行:

1. **快扫**:50 MHz – 1 GHz 以 1 MHz 步长扫频,每点驻留 100 ms,记录功率谱
2. **粗候选**:挑出 top-5 强谱线(信号 > 噪底 + 15 dB)
3. **细识别**:对每个候选频点做 IQ 采集 1 秒,FFT + 30 Hz 周期性自相关,识别真实的 EM Eye 泄漏(其他干扰如 FM 广播无 30 Hz 周期性)
4. **锁定 + 漂移补偿**:选 SNR 最高的频点,持续锁定;LDSDR AD9363 TCXO 频率稳定度 ± 25 ppm,叠加 PC 端软件 PLL 补偿 ± 50 ppm 范围

**频点漂移来源**:DUT 内部 PLL 与攻击设备 LO 的频率差,典型 < 50 ppm,在 1 GHz 处即 ± 50 kHz,远小于 8 MSPS 带宽,软件补偿无压力。

## §4.3 传输方案决策表

**表 4.3  原始 IQ 直传 vs 板上重建对比**

| 方案 | 数据率 | PC 算力需求 | 算法迭代灵活性 | 延迟 | 选择 |
|---|---|---|---|---|---|
| **v1 千兆 Ethernet 原始 IQ 直传** | 单 RX 192 Mbps / 双 RX 384 Mbps | 高(PC GPU 跑 pix2pix)| 最大(算法在 PC 端任意改) | 100 ms+ | **选定 Phase 1** |
| **v2 板上 emeye_accel 加速 + 8-bit 解调流** | 单 RX 32 Mbps / 双 RX 64 Mbps | 低(PC 只做精修)| 设计时锁定,改 RTL 才能换算法 | < 10 ms | **Phase 2 演进** |
| WiFi 6 传原始 IQ(舍弃) | 同上,但 BW 限 200 Mbps 实际 | 同 | 同 | + 100 ms 无线抖动 | 否决(LDSDR 不带 WiFi)|
| LDSDR USB 2.0 OTG 传 IQ(舍弃) | 限制到 ~ 10 MSPS / 30 MB/s | — | 同 | — | 否决(带宽不够双 RX)|

**选定路径**:**v1 千兆 Ethernet 原始 IQ 直传**(双 RX 384 Mbps,占用千兆 Ethernet ~ 48 %,余量充足),Phase 2 在板上做 emeye_accel 加速。

**v1 → v2 演进的工程意义**:
- v1 让算法快速迭代(Python 改一行代码 → 立刻测试)
- v2 在算法稳定后把热路径下沉到 FPGA,数据率降低 12 倍(384 → 32 Mbps),为 Phase 3 无线版本(USB-WiFi dongle 5 GHz 实际带宽 ~ 200 Mbps)铺路

## §4.4 主控 SoC:直接用 LDSDR PS

### §4.4.1 决策:不外接 RPi CM4

原计划在 LDSDR 后接 Raspberry Pi CM4 8 GB Lite 作为主控,提供 ARM A72 算力 + WiFi 6。Day 1 阶段重新评估后**取消该决策**,直接用 LDSDR 板内的 Zynq-7010 PS。

**表 4.4  LDSDR PS 取代 CM4 的论证**

| 项 | LDSDR Zynq-7010 PS(选定) | RPi CM4 8 GB Lite(取消) | 节省 |
|---|---|---|---|
| CPU | ARM Cortex-A9 双核 @ 866 MHz | Cortex-A72 四核 @ 1.5 GHz | 算力降低,但够用 |
| 内存 | 512 MB DDR3 | 8 GB DDR4 | 减少,Phase 1 PC 端做重 lift |
| 网络 | 千兆 Ethernet(直接) | 千兆 Ethernet + WiFi 6 | WiFi 由 PC 笔记本承担 |
| OS | Buildroot Linux 5.15(候选人 BYO,OFDM 项目同款)| Raspbian 64-bit | **候选人已有 BSP 经验** |
| SDR 控制 | iio_attr 直接控制 AD9361 | 通过 USB 转串口控制 | 减少一层桥接 |
| BOM | 0(已含在 LDSDR 板) | ¥ 1000(CM4 模组 + 载板)| **省 ¥ 1000** |
| PCB 占用 | 0(已含)| 80 × 60 × 12 mm | **省一块载板** |
| 启动时间 | 5 s(单 SoC) | 25 s(双 SoC 串联)| 启动快 |

**唯一代价**:PS 端需要跑数据搬运任务(从 PL 取 IQ → 千兆 PHY DMA),Zynq-7010 PS 算力实测可承担(候选人 OFDM 项目验证)。

### §4.4.2 软件栈

**LDSDR PS 端 Linux 5.15(候选人 BYO Buildroot rootfs)**:
- iio_attr 用户态工具配置 AD9361 LO、增益、采样率、滤波器
- libiio-dame 服务端,通过千兆 Ethernet socket 把 IQ 流推送到 PC
- Python 端 GNURadio + pyadi-iio 库做实时采集与分析

**PC 端(笔记本)算法管线**:
- 接收双 RX IQ 流(对齐时戳)
- 频点跟踪 + AGC 反馈控制(回传到 LDSDR)
- 幅度解调 + 30 Hz 自相关 → Tf / Tr 估计
- 像素重排 + pix2pix GAN 精修(GPU 加速,候选人本地工作站或实验室 GPU 服务器)

## §4.5 Sidebar — 板上 FPGA 加速路线图(Phase 2)

利用 LDSDR Zynq-7010 PL 实现 EM Eye 重建管线热路径的硬件加速,目标:

| 模块 | 功能 | 资源占用估算 | 候选人能力对应 |
|---|---|---|---|
| `magnitude_cordic` | $|I + jQ|$ CORDIC 整数幅度计算 | < 5 % LUT | OFDM 项目 BPSK / QPSK 软解调复用 |
| `autocorr_30hz` | 30 Hz 周期自相关 + 峰值检测 | 8 % LUT + 32 KB BRAM | OFDM 帧同步 cross-correlation 复用 |
| `decimator_8m` | 56 MSPS → 8 MSPS 抽取 + AAF | 12 % LUT + 4 DSP slice | LDPC 解码器 FIR 链路复用 |
| `iq_to_8bit` | 12-bit IQ → 8-bit 解调流 | < 2 % LUT | — |
| `axi_dma_streaming` | PL → PS Linux 内核 DMA | < 5 % LUT | OFDM 项目 AXI-Stream / AXI-Lite 框架复用 |

**预期效果**:
- 输出数据率:**192 Mbps → 32 Mbps**(12 倍压缩)
- 端到端延迟:100 ms → < 10 ms
- LDSDR 千兆 Ethernet 占用:48 % → 4 %

**候选人能力背书**:
- emeye_accel RTL 候选人已在 Phase 0 之前完成首版 Vivado 工程(详见"Pre-Phase 0 已完成工作"章节),仿真通过
- LDPC 项目的 BER = 0 板级验证证明 PS-PL 协同链路稳定
- XCZU3EG HLS LPR CNN 项目的 675 ms 端到端记录证明候选人可在 FPGA 上跑接近 pix2pix 复杂度的网络(若 Phase 2 决定做板上 pix2pix 备份方案)

---

# 第五章 主要器件选型 BOM

完整 BOM 见表 5.1,涵盖 Route A Phase 1 单台原型所需全部器件。**BYO 标注的元件不计入 BOM 成本**。

**表 5.1  Route A Phase 1 完整 BOM**

| 编号 | 模块 | 主选型号 | 替代型号 | 单价 (¥) | 选择理由 |
|---|---|---|---|---|---|
| 1 | **耦合**(主路) | Tekbox TBCP2-1000(100 kHz – 1 GHz) | Pearson 411(5 Hz – 20 MHz,备用低频) | 4,500 | NIST 校准 + Phase 0 第 1 周可用 + 频段完整 |
| 2 | **耦合**(辅路 >500 MHz) | Murata GA355 4.7 pF / 1 kV NP0 × 2 串联 | TDK CGA9 4.7 pF / 1 kV | 30 | 双重失效保护 + RF 低损耗 |
| 3 | **保护(TVS)** | Bourns CDSOT23-T05LC | TI TPD3E001 | 8 | C < 1 pF @ 1 GHz,RF 透明 |
| 4 | **保护(DC 隔直)** | Murata GRM18 NP0 1 nF / 100 V × 2 | TDK CGA3 NP0 1 nF | 6 | 温度系数 ± 30 ppm,无压电 |
| 5 | **保护(GDT)Phase 2** | Bourns 2026-23-SM | EPCOS B88069X8731B502 | 12 | Phase 1 不需要(USB 供电) |
| 6 | **保护(MOV)Phase 2** | Littelfuse V275LA20A | TDK B72207S2271 | 8 | Phase 1 不需要 |
| 7 | **保护(共模扼流)Phase 2** | Würth 744232222 | Coilcraft CMTI-83-2-T | 25 | Phase 1 不需要 |
| 8 | **滤波 Stage 1(必备)** | Murata 150 pF / 56 pF NP0(C1, C3) | TDK 同规格 | 4 | LC HPF 4 阶 Bw 50Ω fc = 30 MHz |
| 9 | | Coilcraft 0603HP 150 nH / 330 nH(L2, L4)| Murata LQW18A | 12 | Q > 50 @ 100 MHz |
| 10 | **LNA**(主放大) | **ERA-4SM+ × 2 级联(BYO)** | Mini-Circuits PGA-103+ × 2 | **0**(BYO) | 候选人已完成,VNA 实测 +28 dB,5.6 M – 3 G |
| 11 | **LNA**(Phase 1 备用第三级) | Mini-Circuits PGA-103+ | PSA4-5043+ | 100 | 仅在 Phase 0 测出 SNR 不够时启用 |
| 12 | **滤波 Stage 2(可选)** | Murata SAFEB200/SAFEA450/SAFFB942 SAW | EPCOS B39 系列 | 250 | Phase 0 实测决定是否启用 |
| 13 | **RF 开关(可选)** | Peregrine PE42423 SP4T | ADRF5040 | 100 | 候选人有 XCZU3EG LPR 项目使用经验 |
| 14 | **SDR** | **LDSDR 7010 rev2.1(BYO)** | LimeSDR Mini 2.0 | **0**(BYO) | 候选人 BYO + 千兆 Ethernet + 2 RX |
| 15 | **主控** | **LDSDR Zynq-7010 PS(BYO)** | Raspberry Pi CM4 8 GB Lite | **0**(已含)| Buildroot Linux + iio_attr,候选人 OFDM 项目同款 |
| 16 | **电源(模拟 LDO)** | TI TPS7A47 | LT3045 | 20 | 4 nV/√Hz 超低噪声,LNA 净化电源 |
| 17 | **电源(数字开关)** | TI TPS54320 | LM5085 | 15 | LDSDR USB 5 V → 1.8 V 数字电源 |
| 18 | **电源(USB-C 输入)** | Maxim MAX14778 + ESD7104 | TI TPD1E10B06 | 30 | USB-C 5 V/3 A + ESD 保护 |
| 19 | **PCB(模拟前端)** | 4 层 80 × 60 mm,RF 路径 Rogers RO4350B | FR-4 全板(性能略降)| 400 | 小批量打样 5 块,含贴片 |
| 20 | **接插件 + 屏蔽件** | SMA × 3(PCB 直焊)+ Ethernet RJ45 + USB-C + 铜罩 | 同等 | 60 | 含 EMI 衬垫 |
| 21 | **网线** | CAT6 1 m | CAT5e | 10 | LDSDR → PC |
| 22 | **外壳(Phase 1)** | 3D 打印 ABS,100 × 60 × 30 mm | PETG | 150 | 快速迭代 2 次 |
| 23 | **外壳(Phase 2)** | CNC 铝合金,带 EMI 衬垫 | 不锈钢冲压 | 800 | Phase 2 演进至插头形态时使用 |

**Phase 1 BOM 净成本汇总**:

| 类别 | 金额 (¥) | 备注 |
|---|---|---|
| 主路耦合 + 辅路 | 4,530 | Tekbox(大头) + HV 电容 |
| 保护链 Phase 1 必备 | 14 | TVS + DC 隔直 |
| 滤波 Stage 1 必备 | 16 | LC HPF |
| LNA(BYO)| 0 | 候选人 ERA-4SM+ × 2 |
| 备用 LNA 第三级 + Stage 2 BPF | 450 | 仅在 Phase 0 触发时启用 |
| SDR + 主控(BYO)| 0 | LDSDR + Zynq PS |
| 电源 + USB-C | 65 | 含 ESD |
| PCB | 400 | 4 层 + RO4350B 局部 |
| 接插件 + 屏蔽 | 60 | |
| 网线 | 10 | |
| 外壳 Phase 1 | 150 | 3D 打印 |
| **基线 BOM 合计** | **5,245** | **含 Tekbox 大头** |
| **不含 Tekbox(若实验室借用)** | **745** | 仅工程化部分 |

---

# 第六章 整体成本估算与交付计划

## §6.1 BOM 成本(Route A 单台原型)

详见第五章 §5.1 表 5.1。Phase 1 单台原型 BOM 合计 **¥ 5,245**(含 Tekbox CT)或 **¥ 745**(若实验室借用 Tekbox)。BYO 资产(LDSDR + ERA-4SM+ × 2 LNA + Vivado / HLS / Buildroot 工具链)估值 ¥ 15,000–20,000,**不计入项目预算**。

## §6.2 NRE(非经常性工程)成本

**表 6.1  Phase 0 + Phase 1 + Phase 2 NRE 成本汇总**

| 类别 | 项 | 金额 (¥) | 说明 |
|---|---|---|---|
| **Phase 0**(3 周) | Tekbox TBCP2-1000 CT(若需采购) | 4,500 | 若实验室有则为 0 |
| | Raspberry Pi 4B × 2 + Camera Module V1.3 × 2 | 1,160 | 论文同款 DUT |
| | 目标 COTS 摄像头 × 4(Wyze / Dafang / 360 / Pixel)| 1,200 | 多设备验证 |
| | SMA 同轴线 + 转接头 + 杂项 | 800 | 调试耗材 |
| | 隔离变压器 1:1 220V/1kVA(若需采购)| 1,200 | 若实验室有则为 0 |
| | **Phase 0 总采购**(最坏情况) | **8,860** | 含全部商用器材 |
| | **Phase 0 实际采购**(实验室借用 Tekbox + 隔离变压器) | **3,160** | 仅 DUT + 耗材 |
| **Phase 1**(12 周) | PCB 打样(2 次迭代,每次 5 块) | 1,500 | 含贴片,RO4350B 顶层 |
| | 3D 外壳打样(2 次迭代) | 300 | ABS,80 × 60 × 25 mm |
| | 测试设备时间(VNA / 频谱仪租用)| 3,000 | 实验室借用,记入机时 |
| | 调试耗材(锡膏 / 酒精 / 防静电包装) | 300 | |
| | **Phase 1 NRE 小计** | **5,100** | |
| **Phase 2**(8 周) | 6 层集成 PCB(优化版,1 次)| 2,500 | 增加层数 + IEC 间距 |
| | CNC 铝合金外壳 | 800 | 替代 3D 打印 |
| | 自研小型化 CT 磁芯 + 工艺迭代 | 600 | Fair-Rite 磁芯 + RG-178 + 工具 |
| | 备用 LDSDR(并行开发)| 1,500 | 防硬件故障阻塞 |
| | 频谱仪扩展头(如需 > 3 GHz)| 600 | 备用 |
| | **Phase 2 NRE 小计** | **6,000** | |
| **NRE 总计** | | **~ 14,260** | 最坏情况(全采购);实际可压到 **~ 5,300**(实验室借用大头) |

## §6.3 工时与里程碑

**1 RA × 6 个月全职**(按 22 个工作日/月计,共 132 个工作日)。

**Phase 0 — 可行性验证(Week 1–3,3 周)**:
- **目标**:在现成器材上复现 EM Eye on RPi V1 + 用 Tekbox CT 验证电源线传导可行性
- **Go/No-Go 决策门**:见 §2.6
- **关键交付**:Phase 0 实验报告(信号强度实测、Tf/Tr 估计精度、3 个 COTS 设备扫描结果)+ Phase 1 设计修正建议

**Phase 1 — 工程原型(Week 4–15,12 周)**:
- **W4–W7**:模拟前端板设计 + PCB 打样第 1 版 + 联调 LNA / 滤波链
- **W8–W11**:LDSDR Buildroot rootfs 移植 + emeye 算法 Python 实现 + 多频段双 RX 融合验证
- **W12–W14**:PCB 打样第 2 版(修正 v1 问题)+ 3D 外壳 + 整机集成 + 多 DUT 验证
- **W15**:Phase 1 评审,出 v1 完整工程原型

**Phase 2 — 集成 + 验证(Week 16–24,9 周)**:
- **W16–W19**:emeye_accel RTL 板上集成 + PS-PL 联调(候选人 OFDM 经验直接迁移)
- **W20–W22**:6 层集成 PCB + CNC 铝合金外壳 + 自研小型化 CT 验证(Phase 2 学术延伸)
- **W23–W24**:多设备 + 多场景(实验室 / 模拟办公环境)验证 + 终版报告

**Phase 3(可选,Week 25+)**:Route B 插头形态演进 + EMC Class B 预测试 + IEC 61010 安规准备。**Phase 3 不在本提案 6 个月预算内**。

## §6.4 Gantt 表(文字版,按周)

```
W:   1  2  3 | 4  5  6  7  8  9 10 11 12 13 14 15 | 16 17 18 19 20 21 22 23 24
Phase 0  ========                                                               (可行性 + Go/No-Go)
Phase 1            ===========                                                   (模拟前端 PCB v1 + LNA 联调)
                              ===========                                        (LDSDR rootfs + 算法 Python)
                                          ===========                            (PCB v2 + 外壳 + 整机集成)
                                                       =                         (Phase 1 评审)
Phase 2                                                  =================       (板上 emeye_accel + 自研小 CT)
                                                                          =====   (多设备验证 + 终版报告)
```

## §6.5 总预算汇总

**表 6.2  6 个月项目总预算**

| 类别 | 金额 (¥) | 备注 |
|---|---|---|
| 候选人 BYO 资产(LDSDR + LNA + 工具链)| 0(估值 ~ 15,000–20,000)| 不计预算 |
| Phase 0 采购(实际,实验室借用大头) | 3,160 | 完整 ~ 8,860 |
| Phase 1 BOM(单台原型) | 5,245 | 含 Tekbox |
| Phase 1 NRE(PCB / 外壳 / 测试 / 耗材)| 5,100 | |
| Phase 2 采购 + NRE | 6,000 | 含备用 LDSDR + 自研 CT 探索 |
| **项目硬件 + NRE 合计** | **~ 19,505** | 最低 ~ 14,000(实验室借用充分)|
| RA 津贴(¥ 2,000 / 月 × 6) | 12,000 | 按校内 RA 标准 |
| **项目总成本** | **~ 31,500** | 区间 26,000 – 36,000 |

**为什么这是诚实可执行的预算**:
1. **BYO 资产省去 SDR + LNA 大头**(否则 ~ ¥ 4,500 + 自研 LNA 工时)
2. **Phase 0 Go/No-Go 限制沉没成本**:即使 No-Go,项目仅投入 < ¥ 10,000 即可终止
3. **Phase 2 学术探索(自研 CT)与 Phase 1 主路径解耦**:即使 Phase 2 自研失败,Phase 1 已交付可用原型
4. **不依赖外购昂贵设备**:LISN / 频谱仪 / VNA 全部假设实验室公共资源借用,这是合理的硬件实验室基础设施前提

## §6.6 风险驱动的预算保留

**表 6.3  Phase 0 后可能触发的应急预算**

| 风险 | 触发条件 | 应急预算 (¥)| 应对措施 |
|---|---|---|---|
| 电源线传导损耗 > 60 dB | Phase 0 测目标 SNR < 5 dB | 3,000 | 启用第三级 LNA(PGA-103+ + PCB 重设计) |
| Tekbox >500 MHz 段性能不足 | VNA 实测 -3 dB 在 600 MHz 之前出现 | 1,500 | 启用辅路 HV 电容 + 软件融合 |
| LDSDR 单板故障 | 任意时点 | 1,500 | 备用 LDSDR(Phase 2 已含)|
| Stage 2 BPF 必须启用 | Phase 0 测出 LNA 接近饱和 | 350 | SAW + RF 开关 |
| **应急预备金合计** | | **~ 6,350** | 占总硬件预算 ~ 30 % |

---

# 章节交叉引用索引

| 主题 | 章节 |
|---|---|
| 形态决策 Route A vs B | §1.1, §1.4 |
| 物理机制(MIPI 共模产生)| §2.1 |
| 耦合方式权衡 | §2.2 |
| 主路 Tekbox CT 选型 | §2.3, §5.1 第 1 行 |
| 辅路 HV 电容 | §2.3, §5.1 第 2 行 |
| 保护链(TVS / 隔直 / HPF)| §2.4, §5.1 第 3–9 行 |
| Phase 0 Go/No-Go 决策门 | §2.6, §6.3, §6.5 |
| ERA-4SM+ × 2 LNA(候选人 BYO)| §3.1, §3.2 链路预算,§5.1 第 10 行 |
| 链路预算 + Friis NF | §3.2, §6.5 风险预算 |
| 可切换 BPF Stage 2 | §3.3, §5.1 第 12–13 行 |
| LDSDR 7010 选型 | §4.1, §5.1 第 14 行 |
| 频点跟踪算法 | §4.2.2 |
| 传输方案 v1/v2 | §4.3 |
| LDSDR PS 取代 CM4 | §4.4 |
| Phase 2 板上 emeye_accel | §4.5, §6.3 Phase 2 工时 |
| Phase 1 BOM | §5.1, §6.1 |
| NRE 成本 | §6.2 |
| 工时与 Gantt | §6.3, §6.4 |
| Phase 2 自研小型化 CT | §6.2 Phase 2 NRE, §1.4 演进路线 |

详细的候选人前期工程实绩(LNA 测试报告 / OFDM LDPC 项目 / XCZU3EG LPR / EC800M / RK3568 移植等)**详见独立的"Pre-Phase 0 已完成工作"章节**,本主体稿不重复展开。

---

**文档结束**
