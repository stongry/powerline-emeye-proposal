# 🎯 会议主参考文档 — 一站式

**会议**:PhD 闫浩然学长,2026-05-13 晚上,线上 30-60 分钟
**目标**:获取信号水平 + 实验室设备 + 耦合方式 + 架构 sanity check
**心法**:**诚实 > 装懂,具体 > 模糊,有方案 > 求指引**

> 本文件整合了之前所有面试准备文档:`meeting_prep.md` + `honest_talking_points.md` + `phd_questions.md` + `theoretical_derivations.md` 的精华。开会时只需打开这一个文件。

---

## 目录(快速跳转)

- [⚡ 30 秒速记](#-30-秒速记)
- [📋 我们手上的设备清单](#-我们手上的设备清单)
- [🔴 必问的 4 个核心问题](#-必问的-4-个核心问题)
- [💬 PhD 可能问你的 + 回答模板](#-phd-可能问你的--回答模板)
- [✅ 仿真和 FPGA 实际状态](#-仿真和-fpga-实际状态)
- [🧮 推导追问参考(RF/模拟)](#-推导追问参考rf模拟)
- [🔧 FPGA 推导追问参考](#-fpga-推导追问参考)
- [🚨 话术红线(不可说的)](#-话术红线不可说的)
- [⏱️ 60 分钟时间分配](#️-60-分钟时间分配)
- [📝 会后立即要做的](#-会后立即要做的)

---

## ⚡ 30 秒速记

### 必做
1. **诚实** — 不会就说不会
2. **带方案** — 不空手讨论,每个问题有具体型号/数字
3. **GitHub repo 浏览器开着** — https://github.com/stongry/powerline-emeye-proposal
4. **笔记本/markdown 准备记录** — 实时记学长答案

### 不做
1. ❌ "我做了 SDR 真实采集"(假的,IQ 是合成的)
2. ❌ "我验证了链路预算"(假的,只验证算法)
3. ❌ 装作什么都懂
4. ❌ 抢话(让学长说,你听)

### 必拿走的 3 个答案
1. **电源线信号水平**(比空气场景弱多少 dB?)
2. **实验室有哪些设备**(CT?VNA?DUT?)
3. **CM/DM 拓扑**(L+N 同向穿芯 vs 单线)

---

## 📋 我们手上的设备清单

### ✅ BYO 资产(可立即用)

| 资产 | 关键参数 | 状态 |
|---|---|---|
| **LDSDR 7010 rev2.1** | XC7Z010 + AD9363(70M-6G)+ 512MB DDR3 + 千兆 Ethernet + 2T2R | ✅ OFDM+LDPC 已验证 |
| **ERA-4SM+ × 2 LNA** | 自研级联,**VNA 实测 +28 dB @ 100 MHz**,5.6M-3GHz 平坦 ±3 dB | ✅ 截图在 `figures/lna_era4sm_x2_gain.PNG` |
| Vivado + HLS + Buildroot | LDSDR 工具链全套 | ✅ 长期使用 |
| GNURadio + Python | SDR 上位机生态 | ✅ 熟练 |
| Vivado HLS 部署经验 | XCZU3EG PL CNN 87.94%/675ms | ✅ github.com/stongry/FPGA-ZYNQ |

### ⚠️ 历史用过待确认

- Keysight E5061B VNA(LNA 测试时用过,**实验室设备?**)

### ❌ 关键缺口(必须依赖实验室)

| 缺口 | 频段需求 | 估价 |
|---|---|---|
| **宽带 CT** | 100 kHz – 1 GHz | Tekbox TBCP2-1000 ¥4,500 |
| 频谱仪 | 9 kHz – 3 GHz | 实验室通用 |
| VNA | DC – 3 GHz | 实验室通用 |
| 隔离变压器 | 1:1 220V | ¥1,200 |
| **RPi 4B + Cam V1** ×2 | 论文同款 DUT | ¥1,200 |
| COTS 摄像头(Wyze/Dafang 等) | Table II 子集 | ¥1,500 |

**Phase 0 全套设备总成本**:**~¥10,000**(实验室全无)→ **~¥3,000**(实验室有 CT)

### 滤波器现状

| 类型 | 是否有 | 备注 |
|---|---|---|
| LC HPF(30 MHz) | ❌ | 可自制,¥15 BOM |
| SAW BPF | ❌ | Phase 1 可选,¥350 |

---

## 🔴 必问的 4 个核心问题

### Q1 — 信号水平量级(P1,必问)

> "学长,论文 EM Eye Table II 给的是空气场景信号(近场 -80 dBm 量级)。**你们电源线传导场景下,信号比空气大概弱多少?同量级、弱 10-20 dB、还是弱 30 dB+?**"

**配套上下文**:
> "我假设 I_CM ~ 1-10 μA,经宽带 CT(转移阻抗 ~5 Ω = -20 dB 插损)后约 -70 dBm。LNA 28 dB + AD9363 30 dB = 总 58 dB 增益,留 35 dB 余量。"

**追问预案**:
| 回答 | 我应该做 |
|---|---|
| 同量级 | ✅ +28 dB LNA 就够了 |
| 弱 10-20 dB | 🟡 加第三级 PGA-103+,总 +50 dB |
| 弱 30 dB+ | 🔴 "需要重新评估,这种情况下能用近场探头改善吗?" |

---

### Q2 — 实验室设备现状(P1,必问)

> "Phase 0 验证我需要这些设备,我手头都没有:
> - 宽带电流探头(100 kHz – 1 GHz)
> - 频谱仪 / VNA
> - 隔离变压器
> - 目标 DUT(RPi 4B + Cam V1 等)
>
> 我已有的是 LDSDR + 自研 ERA-4SM+ × 2 LNA(+28 dB 实测)+ Vivado 工具链。
>
> **实验室目前有哪些现成的?需要采购什么?**"

**追问预案**:
| 回答 | 我应该做 |
|---|---|
| 全套都有 | ✅ Phase 0 第 1 周即可启动 |
| 缺关键件(如 CT) | 🟡 列入项目启动预算 |
| 基本没有 | 🔴 需要 ~¥10k 启动经费,沟通采购流程 |

---

### Q3 — CM/DM 拓扑(P2,强推)

> "**你们做电源线验证时是 L+N 同方向穿过(测共模)还是只穿 L(混合)?DUT 是 3-prong 还是 2-prong?**"

**追问预案**:
- CM 拓扑:✅ 跟我假设一致
- DM 拓扑:⚠️ 我的工装设计要改
- 3-prong:✅ 我的"L+N 同向 + PE 旁路"方案对
- 2-prong:✅ 没 PE,自然 CM

---

### Q4 — 整体架构 sanity check(P3,加分)

> "我的方案:
>
> **宽带 CT → ERA-4SM+ × 2 LNA(BYO,实测 +28 dB)→ LDSDR 7010(千兆 Ethernet + 2RX)→ 笔记本**
>
> 关键选择:
> - LDSDR 2RX → EM Eye Eq.3 多频段融合硬件支持(论文是单 USRP 时分)
> - 删 Raspberry Pi CM4 → LDSDR Ethernet 直连 PC
> - 简化保护链 → 无 GDT/MOV,只有 TVS + DC 隔直 + 30 MHz HPF(夹式 CT 已电气隔离 + USB 供电)
>
> **这架构有明显的坑吗?**"

**追问预案**:
- 说 2RX 没必要:🟡 Phase 1 改单 RX
- 说要回 CM4:🟡 解释 Ethernet 带宽够,听理由
- 说保护链太简化:🟡 听他们标准做法,补足
- 完全 OK:✅ 

---

## 💬 PhD 可能问你的 + 回答模板

### "先简单介绍下你自己?"

```
我是 [姓名],目前 [大三/大四/研究生在读],方向是嵌入式 + FPGA。

近期主要项目:
- LDSDR(国产 Pluto 增强版)上做完整 OFDM+LDPC 收发机 HDL,BER=0 
  板级验证(~53 天前)
- Zynq UltraScale+ XCZU3EG 端到端部署 LPR CNN,87.94% / 675ms 
  (github.com/stongry/FPGA-ZYNQ)
- RK3568 Ubuntu 移植 + RKNN NPU 边缘 AI 部署
- EC800M 语音对话开发

读了 EM Eye 论文后被电源线传导新发现吸引,加上手头硬件正好对上,
所以申请这个 RA。
```

### "为什么对 EM Eye 项目感兴趣?"

```
三个原因:
1. 硬件级安全研究,结合我的 FPGA + RF 背景
2. OFDM 同步问题(Tf/Tr 估计、自相关、IQ 帧对齐)跟 EM Eye 重建结构很像 — 
   之前 debug cp_remove sample-offset 是类似逻辑
3. 电源线传导新方向,从空气推到电源线有工程深度,且攻击距离可能突破论文 5m 上限
```

### "如果被录用,Phase 0 你会怎么做?"

```
Phase 0 三周:
第 1 周:借实验室设备/列采购清单,信号链跑通,VNA 实测前端 S 参数
第 2 周:RPi 4B + Cam V1 复现论文(空气场景对照),建立 baseline
第 3 周:切电源线场景,出 Go/No-Go 报告

主要不确定性是电源线 vs 空气信号水平比例 — 这也是我第一个问题。
弱 20 dB 以内,我们的方案能 cover;弱 30 dB+ 需要重新评估。
```

### "你对 RF/EMC 这块多少经验?"

```
坦白说,RF 经验主要是消费级:LNA 装配 + VNA 测试,理解 S 参数和
链路预算基本概念。

但深度 EMC 设计、屏蔽工程、商用电流探头测量,我没正式做过,需要在
Phase 0 边学边做。这也是为什么 BPF Stage 2、自研 CT 这些我都列为
Phase 0 实测后决定 — 不想盲目堆 RF 元件。
```

### "提案进度怎么样?"

```
已经做了 7 个核心决策,工程文档约 4500 行放在私有 GitHub 仓库。

但坦白说,这些是基于论文阅读 + 工程推理 + 我手头硬件的实测数据,
没有 SPICE 仿真或更深度的电路验证支撑 — 所以才需要您的经验帮我
校准一些关键参数。

如果方便我可以加您看一下私有仓库。
```

### "你 6 个月内能完成什么?"

```
Phase 0 (3 周):可行性验证 + Go/No-Go 决策门
Phase 1 (3 个月):工程原型 — 模拟前端 + LDSDR 集成 + 算法管线
Phase 2 (2 个月):板上加速 — 用我的 LDSDR HDL 经验把幅度解调+帧同步
                做到 FPGA 侧,这是我最大的差异化能力

Phase 2 板上加速我已经写了 RTL 骨架(magnitude + decimator + frame_sync),
Icarus Verilog 单元测试通过。
```

### "你能远程还是必须现场?"

```
[根据实际情况选]:
- 全职现场: "我可以全职在实验室,Phase 0 后熟悉环境会更高效"
- 部分远程: "硬件部分(VNA、信号采集)需在实验室,但 HDL/算法/上位机
            可远程,我手头 Vivado/HLS/Python 工具链齐全"
```

### 5 个坑题(必须警惕)

**坑 1:"你 VNA 测了 LNA,怎么校准的?"**
```
基础 SOL 端口校准,LNA 输出加 30 dB 衰减器保护 VNA 输入。VNA 截图在
仓库 figures/lna_era4sm_x2_gain.PNG,marker @ 100 MHz 显示 -2 dB,
扣除 pad 后实际 +28 dB。
```

**坑 2:"复合磁芯 CT 的 L_m 是多少?"**
```
那部分是桌面研究阶段做的工程估算,基于 Fair-Rite 材质手册 μᵣ 数据,
没实际制作过 CT。Phase 0 主路径是用商用 CT(实验室借/项目采购),
自研 CT 设计留 Phase 2 学术探索。
```

**坑 3:"既然没仿真,怎么知道方案能行?"**
```
论文已经证明攻击物理上成立(空气场景),我的方案主要是工程适配。
能否行的关键是电源线 vs 空气的信号水平比例 — 这正是我第一个问题。
弱 20 dB 内我有信心覆盖,弱 30 dB+ 要重新评估。
```

**坑 4:"LDSDR 在哪?能演示吗?"**
```
[根据真实情况]:
- 在家:"周末/明天可以开机演示 OFDM+LDPC 项目"
- 在外:"目前在 [位置],板子在 [位置],周内可回去演示"
```

**坑 5:"为什么删 GDT/MOV?"**
```
两层原因:
1. 设备 USB 供电不接市电,没有市电雷击通过电源线侵入的路径
2. 信号侧通过夹式 CT 已电气隔离(磁耦合),CT 一二次侧无电气连接,
   GDT/MOV 该保护的威胁场景不存在

但保留 TVS(±5V 钳位)处理 ESD 和 DUT 启动瞬态,这是真实威胁。
这跟 Pluto/LDSDR 自身 SMA 接口设计一致 — 它们也只有 TVS。
```

---

## ✅ 仿真和 FPGA 实际状态

### Python 仿真(`simulation/`)— **跑过,PASS**

**输入**:160×80 合成测试图(渐变 + 同心方框 + 文字 + 亮点)
**输出**:

| 指标 | 值 |
|---|---|
| Tf 估计 | **33.333 ms**(100% 准确) |
| Tr 估计 | 416.62 us |
| **SSIM** | **0.9800** |
| Correlation | 0.9982 |
| 总运行时间 | **2.8 秒** |

**可现场屏幕分享**:
```bash
# 1. EM Eye 摄像头攻击仿真(SSIM 0.98)
cd simulation && python3 emeye_simulation.py

# 2. HDMI TEMPEST 仿真(SSIM 0.99)— 证明方法泛化性
python3 hdmi_simulation.py

# 3. TCP 网络管线 demo — 模拟 LDSDR -> 主机全程
python3 network_demo.py
# 输出: TCP 服务/客户端通信成功,重建图特征可见

# FPGA 单元测试现场跑(全部通过):
cd fpga_accel
iverilog -o /tmp/tb_mag.vvp rtl/magnitude_jpl.v sim/tb_magnitude_jpl.v
vvp /tmp/tb_mag.vvp | tail -10  # PASS

iverilog -o /tmp/tb_cic.vvp rtl/cic_decimator.v sim/tb_cic_decimator.v
vvp /tmp/tb_cic.vvp | tail -10  # PASS

iverilog -o /tmp/tb_fs.vvp rtl/frame_sync.v sim/tb_frame_sync.v
vvp /tmp/tb_fs.vvp | tail -10   # PASS

iverilog -o /tmp/tb_top.vvp rtl/magnitude_jpl.v rtl/cic_decimator.v \
                           rtl/frame_sync.v rtl/emeye_accel_top.v \
                           sim/tb_emeye_accel.v
vvp /tmp/tb_top.vvp | tail -10  # PASS
```

### FPGA RTL(`fpga_accel/`)— **4 个测试全部跑过,全部 PASS**

| 测试 | 模块 | 结果 |
|---|---|---|
| `tb_magnitude_jpl.v` | `|I+jQ|` JPL 近似 | **60/60 PASS**,平均误差 4.29%,峰值 6.80% |
| `tb_cic_decimator.v` | 8× boxcar 抽取 | **11/11 PASS**(constant / ramp / alternating) |
| `tb_frame_sync.v` | Blanking 帧同步 FSM | **5/5 PASS**(ACTIVE/BLANK 转换、frame_idx 递增、短 blanking 忽略) |
| `tb_emeye_accel.v` | **顶层端到端集成** | **PASS** — 1156 AXI-Stream 输出,4 frame_starts 检测 |

**仿真工具**:Icarus Verilog 13.0(开源,无需 Vivado license)

**关键 bug 修复**:
- 顶层 round-robin 输出原本没有缓冲,两通道同时输出时会丢样本
- 修复:每通道加 1 深度 pending buffer + 优先级回退
- 修复后:Phase 1 测试 1024 输入 → 128+128 = 256 输出(完美匹配 8× 抽取率)

**Vivado 2024.2 实际综合数据**(target XC7Z010CLG400-2,远程构建服务器):

| 资源 | 估算 | **Vivado 实际** | XC7Z010 占用率 |
|---|---|---|---|
| Slice LUT | 600 | **420** | **2.39%** |
| Slice FF | 476 | **821** | 2.33% |
| BRAM | 1 | **0** | 0% |
| DSP | 0 | **0** | 0% |

**模块分解**(hierarchical):
- magnitude_jpl × 2: 152 LUT / 148 FF
- cic_decimator × 2: **34** LUT / 62 FF(估算 100,实际省 66%)
- frame_sync × 2: 203 LUT / 518 FF
- 顶层 + AXI buffer: 33 LUT / 93 FF

**Timing**:Setup slack +0.242 ns @ 100 MHz(我们实际 8 MHz,余量 12.5×),Hold +0.523 ns。

**综合 + Place&Route 全部 PASS**。完整 log: `fpga_accel/synthesis_reports/synth.log`

**完整 FPGA 完成度**(诚实分层):
- ✅ 50% — 4 个 RTL 模块全部写完 + 4 个测试全部 PASS
- 🟡 还差 30%:Vivado 集成(.xdc/AXI-Lite/BD Tcl)、PS 侧 Linux 驱动、板级 bring-up
- 🔴 还差 20%:Phase 3 高级功能(多频段融合、硬件自相关、ML 推理)

### 真实状态三层区分

| 层级 | 内容 |
|---|---|
| ✅ **真实现** | EM Eye Eq.2 算法管线、FPGA 4 测试全 PASS、**HDMI TEMPEST 泛化验证(SSIM 0.99)**、**TCP 网络管线主机端代码** |
| 🟡 **仿真桩** | IQ 数据合成(LDSDR-side 模拟)、Vivado 综合 / bitstream 未做 |
| ❌ **未实现** | 多频段融合(Eq.3)、pix2pix GAN、真实 RF 捕获、LDSDR PS C 程序、板级 bring-up |

### 关于"能否现在烧板测试"(2026-05-13 更新)

**Day 2 晚 已完成**:
- ✅ 远程构建服务器(10.24.79.1)Vivado 2024.2 综合 + Place&Route **真实跑通**
- ✅ 实际资源数字 420 LUT / 821 FF / 0 BRAM / 0 DSP(占 XC7Z010 2.39% LUT)
- ✅ Timing 100 MHz 闭合(slack +0.242 ns)
- ✅ Post-impl checkpoint saved

**还差**(需要 LDSDR 实际接到能烧板的机器才能做):
- Vivado BD 集成到 LDSDR ofdm_ldpc_ldsdr_rf 工程
- 完整 pin 约束 .xdc(.我有 ldsdr_led.xdc 但只 1 个 LED 引脚)
- bitstream 生成 + 烧板
- LDSDR PS Linux TCP forwarder C 代码

但已验证主机端代码 100% 工作:
- `simulation/network_demo.py` 用 Python 线程模拟 LDSDR 整套(IQ+FPGA算法+TCP)
- 主机端 TCP 客户端 + 解包 + 重建代码**与真实硬件 100% 相同**
- 实测 533k IQ → 解包到 66k 样本 → 重建 corr 0.62(8× 抽取后预期)
- 网络协议、32-bit packing、frame_idx 标签、reshape 全部正确

**还差**(Phase 2 启动后):
- Vivado 集成 emeye_accel_top 到 LDSDR BD
- LDSDR PS Linux 写 TCP 转发(~100 行 C)
- 板级综合 + bitstream
- 天线接 RX1 + 实际 RF 捕获

---

## 🧮 推导追问参考(RF/模拟)

### 1. CT 转移函数

**公式**:`V₂ = R_L × I₁ / N`

代入(5 匝,50Ω,I_CM = 1μA):
- V₂ = 50 × 1μA / 5 = 10 μV
- P = V²/R = -87 dBm
- 转移阻抗 Z_T = 10 Ω
- S21 理论 = -14 dB,实测 ~-25 dB(含磁芯损耗)

### 2. 共模 vs 差模

**分解**:I_L = I_CM + I_DM, I_N = I_CM - I_DM

**L+N 同向穿芯**:Φ_CT ∝ I_L + I_N = **2·I_CM**(DM 完全抵消)

**实际 DM 抑制比**(几何不对称导致):
```
DM_Rejection ≈ 20·log(D_window/δ_offset)
            = 20·log(7.9mm/0.5mm) = 24 dB + 几何不对称 8 dB
            = ~32 dB
```

工频 1A → 32 dB 抑制 + HPF → **-99 dBm 完全无害**

### 3. Friis 噪声系数级联

**公式**:`NF_total = NF₁ + (NF₂-1)/G₁ + (NF₃-1)/(G₁·G₂)`

代入 ERA-4SM+ × 2 + AD9363:
- NF₁ = 3.5 dB → 2.24,G₁ = 14 dB → 25.1
- NF₂ = 3.5 dB → 2.24,G₂ = 14 dB → 25.1
- NF₃ = 3 dB → 2,G₃ = 30 dB → 1000

```
NF_total(线性) = 2.24 + 1.24/25.1 + 1/630 = 2.29
NF_total(dB) = 10·log(2.29) = 3.6 dB
```

**几乎完全由第一级 ERA-4SM+ 决定**(为什么需要外置 LNA)。

### 4. 噪底 + MDS

**热噪底**(50Ω 系统,56 MHz BW):
- P_noise = kTB = -174 + 10·log(56e6) = **-96.5 dBm**

**加 NF**:-96.5 + 3.6 = **-92.9 dBm**(56 MHz BW 整链噪底)

**用 8 MSPS 采样**(论文设定):约 **-101 dBm**

**MDS**(SNR=0 dB):**-93.5 dBm**;加 LNA 28 dB → **-121.5 dBm**

### 5. SRF(自谐振点)

**5 匝绕组空气芯电感**:`L = N² · μ₀ · π · r_avg² / l_path ≈ 81 nH`

**寄生电容**(Teflon 5 匝):C_parasitic ~5-10 pF

**SRF = 1/(2π·√(L·C))**:**177-400 MHz**(取决于 C)

⚠️ **诚实修正**:之前文档说 SRF 600-800 MHz 过乐观,5 匝实际 ~200-400 MHz,所以 **Phase 0 用商用 CT(Tekbox)更稳健**。

### 6. HPF 4 阶 Butterworth

50Ω,fc = 30 MHz:
- C₁ = 150 pF, L₂ = 150 nH, C₃ = 56 pF, L₄ = 330 nH
- 50 Hz 衰减:理论 -462 dB,实际 -100 ~ -120 dB

---

## 🔧 FPGA 推导追问参考

> 详见 `fpga_accel/doc/fpga_derivations.md`(530 行 8 章节)。这里是会议速查精简版。

### F1. JPL 幅度近似

**公式**:
$$\text{mag}_{\text{JPL}} = \max(|I|, |Q|) + \frac{3}{8} \cdot \min(|I|, |Q|)$$

**为什么 0.375 (= 3/8)**:
- $\sqrt{1+r^2}$ 在 $r \in [0,1]$ 最优线性近似系数 ~0.4
- 0.375 = **1/4 + 1/8 = (>>2) + (>>3)** → **纯移位 + 加法,零 DSP**

**实测精度**(60 个测试向量):
- 平均误差 **4.29%**
- 峰值误差 **6.80%**(JPL 文献规格 ~7% 内)
- HW vs SW 全部在 2 LSB 内(移位截断容差)

**追问**:"为什么不用 CORDIC?"
> "CORDIC 600 LUTs + 5 DSPs + 16 cycles,JPL 73 LUTs + 0 DSP + 3 cycles。EM Eye 不需要绝对精度(链路 NF 3.5 dB 已主导),JPL 23 dB SNR 在系统噪底之上不是瓶颈。"

---

### F2. Boxcar 抽取器传递函数

**公式**:
$$H(z) = \frac{1}{N} \cdot \frac{1 - z^{-N}}{1 - z^{-1}}, \quad |H(e^{j\omega})| = \frac{1}{N} \left|\frac{\sin(\omega N/2)}{\sin(\omega/2)}\right|$$

**关键性质**(N=8, fs=8 MSPS, fo=1 MSPS):
- 零点位置:$f_{\text{null}} = k \cdot f_s/N$ = **1, 2, 3, 4 MHz**
- 通带 sinc droop @ fo/2: **−3.92 dB**
- 实际混叠抑制(受 12-bit 量化限):约 **−50 dB**

**追问**:"够不够?"
> "对 EM Eye 信号窄带特性够用。如果需要更深抗混叠,升级到 3 阶 CIC,但代价 4× LUT。"

---

### F3. 帧同步 FSM

**状态机**:
```
ACTIVE → BLANK: avg_amp < threshold 持续 64 次 (BLANK_MIN)
BLANK → ACTIVE: avg_amp ≥ threshold(立即,触发 frame_start + idx++)
```

**关键参数**:
- 运行平均窗口 W = 16(平滑短噪声)
- BLANK_MIN = 64(确认 blanking,防误判)
- 1 MSPS 抽取后:64 × 1μs = **64 μs 最小检测窗**

**追问**:"假阳性率?"
> "假阳性需要噪声平均值连续 64 个样本低于阈值,概率远小于帧率 30 Hz。Phase 0 实测后可调阈值。"

---

### F4. AXI-Stream Pending Buffer

**问题**:`ch1_sync_valid` 和 `ch2_sync_valid` 都是 1-cycle 脉冲,**抽取边界对齐**,无 buffer 会丢一个。

**修复**:每通道 1-entry pending buffer + 优先级 round-robin + 回退。

**深度证明**:输入速率 1/(8 cycles) per channel,输出速率 1/cycle,**输出 >> 输入,1 深度够用**。

**实测**(tb_emeye_accel):Phase 1 输入 1024 → 输出 128+128 = 256(完美 8× 抽取,**零丢失**)。

---

### F5. 流水线时延

| 模块 | Cycles |
|---|---|
| magnitude_jpl | 3 (abs / max-min / arithmetic) |
| cic_decimator | 2 + 抽取间隔(8) |
| frame_sync | 1 |
| AXI 输出 | 1 (pending buffer) |
| **端到端** | **7 (最优) ~ 14 (最坏)** |

在 8 MHz 时钟下:**875 ns ~ 1.75 μs**。相对帧周期 33.3 ms **可忽略**。

---

### F6. 资源估算(XC7Z010 -2)

| 模块 | LUT | FF | BRAM | DSP |
|---|---|---|---|---|
| magnitude_jpl × 2 | 160 | 96 | 0 | 0 |
| cic_decimator × 2 | 100 | 60 | 0 | 0 |
| frame_sync × 2 | 240 | 120 | 0 | 0 |
| AXI 输出 + buffer | 100 | 200 | 1 | 0 |
| **总计** | **600** | **476** | **1** | **0** |
| **占 XC7Z010** | **3.4%** | 1.3% | 1.7% | 0% |

留 **95%+** 资源给 Phase 3 多频段融合、硬件自相关、ML 推理。

**追问 LUT 数怎么算的**:`fpga_accel/doc/fpga_derivations.md §6` 有逐项分解。

---

### F7. 带宽压缩

| 节点 | 速率 |
|---|---|
| AD9363 IQ(2 ch × 8 MSPS × 12 bit × 2 IQ) | 384 Mbps |
| magnitude 后 | 192 Mbps |
| 抽取 8× 后 | **24 Mbps** |
| AXI-Stream packed(2 ch × 1 MSPS × 32 bit) | 32 Mbps |

**压缩比**:**384 / 24 = 16×**(纯数据)或 **384 / 32 = 12×**(含 packing)

**千兆 Ethernet 余量**:800 Mbps / 32 Mbps = **25× headroom**。

---

### F8. 仿真测试结果(全部 PASS)

| 测试 | 结果 | 关键指标 |
|---|---|---|
| `tb_magnitude_jpl` | **60/60 PASS** | 平均 4.29%,峰值 6.80% |
| `tb_cic_decimator` | **11/11 PASS** | constant / ramp / alternating 全精确 |
| `tb_frame_sync` | **5/5 PASS** | 4 frame_start 触发,short blanking 正确忽略 |
| `tb_emeye_accel`(顶层) | **PASS** | 1156 AXI 输出,4 frame_starts,**0 丢失** |

仿真过程**发现并修复 1 个真实 bug**:顶层 round-robin 无缓冲 → 加 pending buffer 后 100% 通过。

---

### F9. 8 个最可能被追问的 FPGA 问题

| 问题 | 一句话答案 |
|---|---|
| Q: 0.375 怎么来的? | 1/4+1/8 = 移位实现,零 DSP,JPL 文献最优系数 |
| Q: CORDIC 不行吗? | 600 LUTs + 5 DSPs vs 我们 73 LUTs + 0 DSP,EM Eye 不需精度 |
| Q: Boxcar 混叠抑制? | 零点 1-4 MHz,实际 -50 dB(12-bit 限制) |
| Q: BLANK_MIN=64 怎么选? | 64 μs 检测窗,真实 blanking 50-200 μs,Phase 0 实测后微调 |
| Q: 为什么要 buffer? | 1-cycle 脉冲在抽取边界冲突,1-depth pending 够用,**实测零丢失** |
| Q: 端到端时延? | 7-14 cycles = 875 ns-1.75 μs,相对 Tf 33ms 可忽略 |
| Q: 600 LUT 怎么算? | 160+100+240+100,逐项推导在 derivations.md §6 |
| Q: JPL 23 dB SNR 够吗? | 链路 NF 3.5 dB 主导整链 SNR,JPL 在噪底之上不是瓶颈 |

---

## 🚨 话术红线(不可说的)

### ❌ 5 个会露馅的话

1. ❌ "我做了 SDR 真实采集" → IQ 是合成的
2. ❌ "我跑过真实硬件" → LDSDR 没动过(只用过 OFDM+LDPC 项目,跟 EM Eye 无关的硬件)
3. ❌ "我验证了链路预算" → 只验证了算法
4. ❌ "我做了 GNURadio flowgraph" → 纯 Python
5. ❌ "我证明了 SNR 35dB 够用" → SNR 是基于假设算的

### ✅ 替代说法

| ❌ 不说 | ✅ 说 |
|---|---|
| "我做了 SDR 采集" | "我用 Python 仿真了 SDR IQ 数据" |
| "我验证了设计" | "我验证了算法部分,物理层 Phase 0 验证" |
| "效果很好" | "SSIM 0.98" |
| "运行很快" | "2.8 秒" |
| "带宽够" | "192 Mbps,Ethernet 800 Mbps 留余量" |

### 🟡 模糊话术(可用但谨慎)

- ✅ "Simulation models the EM leakage from MIPI byte-clock harmonics"
- ✅ "I've implemented the EM Eye reconstruction pipeline"
- ⚠️ "I've simulated the SDR acquisition" — 字面 OK,但听起来像做了硬件
- ❌ "I've validated the design"

---

## ⏱️ 60 分钟时间分配

| 时段 | 内容 | 时间 |
|---|---|---|
| 0-3 min | 寒暄 + 简短自我介绍 | 3 |
| 3-8 min | 背景陈述:读了论文,做了方案,有几个问题 | 5 |
| **8-25 min** | **🔴 Q1 信号水平 + Q2 设备清单** | **17** |
| 25-40 min | 🟡 Q3 耦合 + 🟢 Q4 架构 sanity check | 15 |
| 40-50 min | 学长问你 → 用 §回答模板 | 10 |
| 50-55 min | 谈下一步:正式提案什么时候交?格式? | 5 |
| 55-60 min | 感谢 + 后续(微信 / GitHub 权限) | 5 |

### 关键时间锚点

- **25 分钟前必须问完 Q1 + Q2** — 不答上来提案没法收尾
- **学长问你超 15 分钟时**:"学长不好意思,我还有几个具体问题想趁这次机会请教..."
- **最后 5 分钟必须确认下一步** — 不能模糊收尾

---

## 📝 会后立即要做的

30 分钟内:

1. **整理学长回答** → 写到 `references/haoran_meeting_notes.md`
2. **更新提案数字**:
   - Q1 答案 → Ch2 链路预算调整
   - Q2 答案 → Ch5 BOM 调整(实验室有就删 ¥4-5k)
   - Q3 答案 → Ch7 风险段
   - Q5/架构建议 → 各章节同步
3. **微信跟进**:简短谢谢消息
4. **GitHub 权限**(如学长说要看):立即操作

### 学长可能的反应预案

| 反应 | 我应该做 |
|---|---|
| 热情、详细解答 | ✅ 顺势把更多问题问完 |
| 冷淡、敷衍 | ⚠️ 抓重点 Q1 + Q2,其他写进提案 |
| 反过来考你 | ✅ 诚实承认会的会、不会的不会 |
| 大量纠正方案 | ✅ 感谢虚心记录,不全盘推翻 — 解释考虑后调整 |
| 想看 GitHub | ✅ **立即加权限**(这是最强信号) |

---

## 会议前 10 分钟最后准备

- [ ] 打开 GitHub repo:https://github.com/stongry/powerline-emeye-proposal
- [ ] 打开本文件(MEETING_MASTER.md)
- [ ] 浏览器开第二个标签:`simulation/output/simulation_result.png`
- [ ] 准备纸笔或开 markdown 实时记录
- [ ] 准备 LDSDR 板上电(如要演示)
- [ ] 测试网络/摄像头/麦克风
- [ ] 喝水,深呼吸

---

## 核心心法(再确认)

> **诚实 > 装懂**
> **具体 > 模糊**
> **有方案 > 求指引**

会议结束后告诉我学长说了什么,我们一起调整提案。加油!
