# Day 1 — 6 个核心决策 + 系统框图

**日期**:2026-05-12
**输出**:这一页文件就是 Day 1 的所有产出,Day 2 起每章的写作以这里的决策为基准。

---

## 决策 1:形态

**选定:Route A USB 供电便携式**(目标 ≤150 × 80 × 50 mm,实际可压缩到 100×60×30 mm)

| 选项 | 优点 | 缺点 | 评分 |
|---|---|---|---|
| **Route A USB 供电便携式** | 设备零接触市电,触电风险归零,无 IEC 61010 认证负担,USB 移动电源/笔记本即供电,现场部署灵活 | 不够隐蔽 | ⭐⭐⭐⭐⭐ v1 |
| Route B 插头适配式 | 隐蔽性好,接近最终形态 | 内含市电,需全套 GDT/MOV 保护链,IEC 61010 + EMC Class B 认证,空间紧 | Phase 2 演进 |

**理由**:
- 设备本体由 USB 5V 供电(移动电源 / USB 充电器 / 笔记本),**与市电完全解耦**
- 唯一与市电"关联"的元件是夹式 CT,但 CT 是电气隔离的磁耦合元件,一次侧(电源线)与二次侧(信号输出)无电气连接
- 安全性大幅提升 + BOM 简化 + 形态自由度提升
- 现场部署能力增强(充电宝、车载 USB、PoE-USB 都能用)

---

## 决策 2:耦合方式(2026-05-13 更新:商用 CT 主路)

**选定:Tekbox TBCP2-1000 商用宽带 CT(Phase 0 采购),自研 CT 作为 Phase 2 学术探索**

### 现实校正

之前曾考虑自研复合磁芯 CT 作为主路径,但实际工程评估发现:
- 磁芯采购周期 7-15 天
- 绕组工艺迭代需 3-4 次实验,每次 0.5 天
- VNA 验证 + 调试 1 天
- **完整自研周期 2-3 周**,且 SRF / DM 抑制等关键参数不可控
- 候选人当前**不在实验室环境**,Phase 0 之前根本无法启动

因此**改为 Phase 0 采购商用 CT**,自研方案的工程分析(见 coupling_refined_analysis.md)保留作为 Phase 2 学术延伸。

### 商用 CT 选型对比

| 候选 | 频段 | 价格 | 决定 |
|---|---|---|---|
| **Tekbox TBCP2-1000** ✅ | 100 kHz – 1 GHz | ¥4,500 | **选定** |
| Tekbox TBCP1-200 | 100 kHz – 200 MHz | ¥2,000 | ❌ 频段不够(>500 MHz 目标覆盖不到) |
| Fischer F-65A | 1 MHz – 1 GHz | ¥10,000+ | ❌ 太贵,性能过剩 |
| Pearson 411 | 5 Hz – 20 MHz | ¥3,000 | ❌ 频段完全不够 |
| HP 11947A(二手) | 9 kHz – 200 MHz | ¥1,500 | ❌ 频段不够 |
| Beehive 100C | 高频近场 | ¥500 | ❌ H 场探头,重复性差 |

### Tekbox TBCP2-1000 关键指标

| 参数 | 值 |
|---|---|
| 频段 | 100 kHz – 1 GHz |
| 类型 | 夹式宽带电流探头 |
| 转移阻抗 | ~5 Ω(平坦) |
| 一次侧通过电流 | 最大 30 A AC |
| 校准证书 | NIST 可追溯 |
| **覆盖 EM Eye Table II** | **12/12 目标频点全覆盖** |

### 自研 CT 的角色:Phase 2 学术延伸

`coupling_refined_analysis.md` 中的复合磁芯 CT 分析、容差研究、SPICE 建模等**全部保留**作为:
- Phase 2 小型化研究方向(把 Tekbox 100 mm 的尺寸压到 20 mm)
- 论文中"工程贡献"部分的方法论
- 学术发表时与商用 CT 对照实验的备用方案

### 关键参数(用 Tekbox 后)

- 工作频段:100 kHz – 1 GHz,完全平坦
- 转移阻抗:5 Ω(等效插损 ~-20 dB,优于自研估算的 -25 dB)
- 体积:OD ~100 mm,**比自研 12.7 mm 大得多**(Phase 1 集成时需考虑)
- 工装兼容:Tekbox 是分体式钳形,可直接夹电源线,**不需要自制 2 芯延长线工装**

---

## 决策 3:保护链(已根据 USB 供电架构简化)

**Phase 1 链路**(夹式 CT 二次侧 → LNA 输入):

```
[CT 二次绕组] → TVS阵列 → DC隔直 → LC高通 → [LNA 输入]
                                    ↓
                            fc=30 MHz, 50Hz 抑制 >100 dB
```

**信号侧不需要 GDT/MOV**(夹式 CT 已电气隔离,无市电侵入风险)。
设备供电走 USB-C,**整机不接触市电**。

| 元件 | 型号 | 参数 |
|---|---|---|
| TVS 阵列(低 C) | Bourns CDSOT23-T05LC | ±5V 钳位,C<1pF @ 1GHz,响应 <1ns |
| 隔直电容 | Murata GRM18 NP0 1nF/100V | 阻 DC,通 RF |
| Stage 1 HPF | C1=150p, L2=150n, C3=56p, L4=330n | 4 阶 Butterworth fc=30MHz |

**Phase 2 演进时再考虑的元件**(插头适配形态):

| 元件 | 型号 | 用途 |
|---|---|---|
| GDT(气体放电管) | Bourns 2026-23-SM | 雷击保护 |
| MOV(压敏电阻) | Littelfuse V275LA20A | 工频钳位 |
| 共模扼流圈 | Würth 744232222 | 共模噪声抑制 |
| 内部 AC-DC | Mean Well IRM-10-5 | 设备自供电 |

---

## 决策 4:LNA

**选定:PGA-103+ × 2 级联,总增益 38–40 dB**

| 选项 | 增益 | NF | 带宽 | 价格 | 决定 |
|---|---|---|---|---|---|
| 论文同款 Foresight FST-RFAMP06 | 40 dB | ~3 dB | DC–3.5 GHz | $207 | 国内不好买,作为论文对标 |
| **Mini-Circuits PGA-103+ × 2** | 38 dB | <1 dB | 50 MHz–4 GHz | ~$50/级 | ✅ **选定** |
| PSA4-5043+ + PGA-103+ | 42 dB | 0.7 dB | 50 MHz–4 GHz | ~$80 | 高端备选 |

**配套**:
- 级间 π 型衰减器(0/3/6 dB 可调)
- 单独铜罩屏蔽腔体
- Rogers RO4350B 微带线(>500 MHz 段)

---

## 决策 5:SDR(LDSDR)— 主控不需要,直接 Ethernet 到 PC(方案 A)

### SDR 选定:LDSDR 7010 rev2.1(候选人已 BYO)

**重大更新**:从原计划的 ADALM-Pluto 升级为 LDSDR,因为这就是候选人手头实际使用的板子(OFDM+LDPC 项目同款)。

**LDSDR 关键能力**(比标准 Pluto 增强):

| 项 | LDSDR 7010 | 标准 ADALM-Pluto | 差异 |
|---|---|---|---|
| 主芯片 | XC7Z010CLG400-2 | 同 | — |
| RF 收发器 | AD9363(解锁到 AD9361,70 MHz – 6 GHz) | 同 | — |
| 内存 | **512 MB DDR3** | 256 MB | 2 倍 |
| 网络 | **千兆 Ethernet + USB OTG** | 仅 USB 2.0 | **巨大优势** |
| RF 端口 | **2 TX + 2 RX(2T2R)** | 1 TX + 1 RX | 双 RX 通道 |
| 扩展 I/O | 38 pin PL + 8 pin PS | 极少 | 可控外部开关 |
| 启动 | TF 卡 + 32M Flash | 内嵌 Flash | 调试方便 |

### AD9363 内部 RX 链(自带 LNA / DDC / ADC)

| 块 | 参数 | 作用 |
|---|---|---|
| 内部 LNA | -3 ~ +14.5 dB 可调 | 第一级增益 |
| 内部混频器 + IF VGA | 0 ~ 50 dB | 中频放大 |
| 内部 ADC | 12-bit, 61.44 MSPS | 数字化 |
| **内部 DDC + FIR** | 可配,带宽 200 kHz – 56 MHz | **替代我们外置 SAW BPF** |
| 内部 NF | 2.5 dB @ 低频, 4-5 dB @ 高频 | — |

**关键含义**:外置 SAW BPF 组(Stage 2)可以**降级为可选/取消**,因为 AD9361 内部 DDC + FIR 已经提供窄带选择性。

### 主控:**取消 CM4,直接 LDSDR Ethernet → 笔记本/PC**(方案 A)

| 原方案 | 方案 A(选定) | 节省 |
|---|---|---|
| LDSDR → CM4 → WiFi 6 → PC | LDSDR → 千兆 Ethernet → PC/笔记本 | ¥1,000(CM4 删除) |

理由:
- LDSDR 千兆 Ethernet 提供 800 Mbps 实际吞吐 → 双通道 IQ(384 Mbps)完全够
- LDSDR 内部 Zynq PS 端跑 Linux,完全可以承担 CM4 角色
- "无线"需求由 PC 笔记本自带的 WiFi 满足,**不需要额外硬件**
- Phase 1 实验室场景下,PC + Ethernet 是标准工作流
- Phase 2(便携场景)再考虑加 USB-WiFi dongle 到 LDSDR

### LNA 设计微调:理由从"补 NF"变成"扩 IIP3"

ERA-4SM+ × 2 外置 LNA(BYO,实测 +28 dB)仍保留,但作用重新定义:

| 配置 | 链路 NF | AD9363 内部增益 | 系统 IIP3 |
|---|---|---|---|
| 仅 AD9363(最大增益) | 3-5 dB | 70 dB | -10 dBm |
| **外置 ERA-4SM+ ×2 + AD9363(最小增益)** | 3.5 dB | 30 dB | **+10 dBm**(↑ 20 dB) |

电源线场景带强干扰(AM/FM 等),**高 IIP3 是关键**,防止三阶交调污染目标频段。

---

## 决策 6:数据传输(方案 A:千兆 Ethernet,无中间主控)

**选定:LDSDR 千兆 Ethernet → PC/笔记本(原始 IQ 直传,无线由 PC WiFi 承担)**

### 带宽估算(完全充足)

| 数据流 | 速率 | LDSDR Ethernet(800 Mbps) | 评价 |
|---|---|---|---|
| 单通道 IQ(8 MSPS × 2 × 12 bit) | 192 Mbps | ✅ 占用 24% | 余量充足 |
| **双通道 IQ(2 × 8 MSPS × 2 × 12 bit)** | **384 Mbps** | ✅ 占用 48% | **支持 2RX 多频段融合** |
| 单通道极限(56 MSPS) | 1344 Mbps | ❌ 超过 | 不会用到 |
| 板上幅度解调流(双通道,8-bit) | 128 Mbps | ✅ 占用 16% | Phase 2 优化 |

### 传输架构(方案 A)

```
[信号链] → [LDSDR AD9363 RX1+RX2] → [千兆以太网] → [PC/笔记本]
                                                       │
                                                       │ 跑 GNURadio / Python
                                                       │ 算法管线:Tf/Tr 估计 + 融合 + pix2pix
                                                       │
                                                       └──→ "无线"由 PC 自带 WiFi 承担
                                                            (Phase 1 不算独立需求)
```

### LDSDR 2T2R 的关键利用

**EM Eye 论文 Eq. 3 多频段融合**原本需要时分采样不同频点。LDSDR 2RX 让我们可以**同时采样**两个目标频点:

```
LDSDR 内部 AD9361:
   ┌── RX1 → LO = 204 MHz → 8 MSPS IQ 流 1 ──┐
   │                                          ├─→ Ethernet → PC 并行融合
   └── RX2 → LO = 255 MHz → 8 MSPS IQ 流 2 ──┘
```

这是论文也没做到的(他们用单 USRP 时分),**写进提案是 v1 baseline 亮点,不是 v2 路线图**。

### Phase 2 板上加速路线图(候选人差异化亮点)

利用 LDSDR Zynq-7010 PL 实现:
- 模块 A:|I+jQ| 整数幅度计算(CORDIC)
- 模块 B:30 Hz 周期自相关,粗估 Tf
- 模块 C:输出双通道 8-bit 解调流(384 → 128 Mbps)
- 主机端只做精修 + 重建,Python 算力轻量化

**候选人 OFDM+LDPC LDSDR HDL 经验** = 直接对应该平台,**Phase 2(3 个月内)可完成**。

---

## 决策 7:滤波策略 — HPF 必选 + BPF 待定

**选定:两阶段滤波 — Stage 1 无源 HPF 必选,Stage 2 可切换 BPF 组待 Phase 0 SNR 实测决定**

### 背景

EM Eye 论文(Appendix F)指出 BPF 是"可改进项"但主实验不用。论文是空气耦合,我们是电源线耦合,**电源线场景的干扰图景显著更恶劣**:AM 广播、FM 广播、室内开关电源 EMI 都直接传导。

### Stage 1(基线,永远在线)

**LC 4 阶高通滤波器 fc=30 MHz**

| 参数 | 值 |
|---|---|
| 拓扑 | 4 阶 Chebyshev LC HPF |
| 截止频率 | 30 MHz |
| 通带插损 | <1 dB |
| 阻带衰减 | >30 dB @ 10 MHz, >60 dB @ 1 MHz |
| 元件 | L=470 nH × 3, C=47 pF × 2 |
| BOM 成本 | ~¥15 |

**作用**:
- 滤掉 AM 广播 (530-1700 kHz)
- 滤掉 FM 广播 (88-108 MHz 部分能量)
- 滤掉室内 SMPS 传导 EMI(<30 MHz)
- 不影响任何 EM Eye Table II 目标频点(全 ≥155 MHz)

### Stage 2(增强项,Phase 1 实测后决定是否上)

**4 段 SAW BPF 通过 SP4T RF 开关切换**

| 频段 | 中心 | 带宽 | 覆盖 Table II 目标 |
|---|---|---|---|
| Band-1 | 200 MHz | 150-250 | RPi V1 (204), Xiaodu (204) |
| Band-2 | 450 MHz | 350-550 | Pixel 3 (515), 360 (450), Dafang (322 边缘) |
| Band-3 | 900 MHz | 800-1000 | WyzeCam (890), Dafang (890) |
| Band-4 | 1500 MHz | 1300-1700 | Pixel 1 (1649), 行车记录仪 (1015/1261/1470) |

**每段 SAW 性能要求**:
- 通带插损 ≤ 3 dB
- 阻带抑制 ≥ 40 dB(距中心 ±100% 处)
- VSWR ≤ 1.5:1
- 群延迟波动 ≤ 50 ns

**RF 开关**:Peregrine PE42423 或 ADRF5040,隔离 >50 dB,响应 <1 μs

**Stage 2 BOM 成本**:~¥350

### 决策依据

| 维度 | 不加 BPF | 仅 HPF | HPF + 可切换 BPF |
|---|---|---|---|
| LNA 饱和风险 | 高(电源线带强干扰) | 中 | 低 |
| SNR 改进 | baseline | +5 dB | +10-15 dB |
| BOM 成本 | ¥0 | ¥15 | ¥350 |
| 开发时间 | 0 | +0.5 周 | +2 周 |
| 推荐阶段 | ❌ | ✅ **Phase 0** | 🟡 Phase 1 看实测 |

### Phase 0 决策门

**触发上 Stage 2 BPF 的条件**(写进提案 §6 Phase 0 Go/No-Go 标准):

如果 Phase 0 实测发现以下任一情况,Phase 1 必须加 Stage 2:
1. LNA 输出端在 100 MHz – 1 GHz 测得带外干扰功率 > -30 dBm(LNA 接近饱和)
2. 目标频点 SNR < 10 dB(论文同等条件应有 ~30 dB)
3. 重建图像有明显条纹干扰(EM Eye Fig. 19 所示的显示器/广播干扰特征)

---

## 系统总框图

(完整 ASCII 草稿见 README.md 同步版,Day 2 转 draw.io 后作为 Figure 1)

```
墙插 → [耦合+保护] → [可选BPF] → [LNA 40dB] → [Pluto SDR] → [CM4] → [WiFi6] → PC
       Fair-Rite CT  SAW×3+开关  PGA-103+×2   AD9363+Zynq  ARM-A72   802.11ax
       GDT/MOV/TVS                                          GNURadio
```

7 个核心模块 + 独立电源域 = 8 模块。

---

## 文献调研产出(占位,Day 1 末填充)

详见 `references/related_work.md`。三组关键词:
1. 电源线传导侧信道(power-line conducted EM TEMPEST)
2. 宽带 CT 设计(broadband ferrite CT 1 GHz)
3. 已有 TEMPEST 经典(Kuhn / Hayashi / de Meulemeester)

---

## Day 1 自检

- [x] 重读 EM Eye §III/§V/§VI-A/Appendix F/H 完成
- [x] 论文笔记 `references/emeye_paper_notes.md` 已建立
- [x] 重读功能需求书,标出 4 Function + 6 章节
- [x] 6 个决策全部锁定,每个都有论文/需求书锚点
- [x] 系统框图 ASCII 完成,Day 2 转图
- [ ] 文献调研 3 组关键词(留 Day 1 下半天执行)
- [ ] Git commit

---

## 候选人现有资产清单(Bring-Your-Own)

**前提**:本提案为求职申请,候选人**不在被雇佣前自费购置实验设备**。提案的工程可信度建立在:论文阅读 + 推理严密 + 候选人现有资产 + 候选人过往项目。

| 资产 | 状态 | 在本项目中的作用 |
|---|---|---|
| **ERA-4SM+ × 2 LNA 级联模块** | 自研已完成,可立即投入 | Phase 0 模拟前端(对标论文 FST-RFAMP06,差 10 dB 增益,够用) |
| **ADALM-Pluto SDR** | 已拥有,做过 OFDM+LDPC 完整开发 | Phase 0 数字采集 + Phase 2 板上加速基础 |
| **Pluto Zynq-7010 HDL 开发链** | Vivado + Buildroot Linux 已通,BER=0 验证 | Phase 2 自研 PL 加速模块的开发基础 |
| **XCZU3EG HLS CNN 开发经验** | github.com/stongry/FPGA-ZYNQ,87.94%/675ms | Phase 2 板上 pix2pix 替代/优化的能力背书 |
| **Vivado / HLS / Buildroot 工具链** | 长期使用 | 减少新人学习曲线 |
| **嵌入式 Linux + Python + GNURadio** | RK3568 Ubuntu 移植 + EC800M 等项目 | CM4 主控开发直接上手 |

### Phase 0 仍需采购/借用清单(写进提案 §6 NRE 部分)

**明确约束**:**候选人不采购任何商用 RF 电流探头**。

被雇佣后 Week 1 内需采购或借用的:

| 设备 | 用途 | 备注 |
|---|---|---|
| 实验室宽带电流探头 / LISN | Phase 0 电源线传导验证(首选 Path A) | 借用实验室公共资源 |
| Fair-Rite 磁芯样品集 + Teflon 线 | 自研最小 CT (Path B,Path A 不可行时) | ~¥600,1-2 天 |
| Raspberry Pi 4B + RPi Camera V1 ×2 | Phase 0 受害设备(对齐论文) | ~¥1,200 |
| 频谱仪 / 矢网(VNA) | 模拟前端调试 + CT 设计验证 | 借用实验室公共资源 |
| 隔离变压器 1:1 220V | 安全调试电源线耦合 | 实验室如无,采购 ¥1,200 |

**关键决策**:
- **Phase 0 探测策略 Path A**:依赖实验室公共电流探头/LISN(首选)
- **Phase 0 探测策略 Path B**:自研最小 CT(Fair-Rite 磁芯 + 5-7 匝绕组,< ¥600),验证范围 1 MHz – 300 MHz,覆盖 EM Eye Table II 中过半目标
- **不采购** Tekbox / Fischer / Pearson 等商用探头

---

## Day 2 启动条件

✅ 所有决策已锁定,Day 2 可直接进入"写 Ch1 + Ch2"流程。
✅ 候选人资产清单已建立,Annex A 撰写有素材。
✅ Phase 0 改为"小批量采购+借用",不再涉及候选人自费实验。
