# 第 X 章 Pre-Phase 0 已完成工作

> 本章列举本提案提交之前(即正式 RA 录用与项目启动之前)候选人已经独立完成的工程工作。所有材料均可在公开 GitHub 仓库与本地工程目录中复现、可审计。其目的有三:**一**,证明候选人对论文方法的理解已经从"读懂"推进到"复现 + 创新扩展";**二**,证明从 Python 高层仿真、Verilog RTL、Vivado 实现、到真硬件烧录与 RF 实测的全链路已经打通;**三**,本提案在第二章给出的工程论断(资源预算、跨时钟域风险、网络管线吞吐)绝大部分有实测数据背书,而不是论文照搬或纸面推演。

---

## §X.0 一句话总览

在提案撰写阶段(共 6 天工程冲刺),候选人已完成:

1. **2 份端到端 Python 仿真**(EM Eye 论文复现 SSIM 0.98 + HDMI TEMPEST 泛化扩展 SSIM 0.9907)+ **1 份 LDSDR → 主机 TCP 网络管线 demo**;
2. **4 个可综合 Verilog 模块** + **4 个 testbench 全部 PASS**(Icarus Verilog,无 Vivado license 依赖);
3. **完整 Vivado 流程**到 `write_bitstream`,目标真器件 **XC7Z010-CLG400-2**(LDSDR rev2.1),产物 `.bit` MD5 已固定;
4. **真板烧录与 AD9361 RF 实测**:LDSDR 千兆 GbE 在线,FPGA Manager `operating`,RX_LO 配到 **204 MHz** EM Eye 频点,RSSI **93.75 dB**,采集 16 KB 真实 IQ 流,dmesg 零错误;
5. **Phase 2 提前规划文档**(AXI-Stream tap 方案 + PS 用户态 TCP forwarder 骨架共 1096 行)。

工程产物总计 **约 6,000 行**(Python + Verilog + C + Markdown 文档),全部在本地工程目录 `/home/ysara/work/powerline-emeye-proposal/` 下。

---

## §X.1 端到端 Python 仿真:从 EM Eye 论文复现到 HDMI TEMPEST 泛化

候选人没有从板子开始,而是先在 Python 上把整条链路跑通,目的是把"论文里的公式"转换成"我手里有的可运行参考实现",后续 FPGA RTL 的输出对错有了 golden reference。

### §X.1.1 EM Eye 论文方法完整复现(参见 EM Eye 论文 Long et al., NDSS 2024)

文件 `simulation/emeye_simulation.py`(501 行)实现了论文方法的 Python 等价:

| 组件 | 实现内容 | 关键参数 |
|------|----------|----------|
| 信号源 | RPi V1 摄像头(OV5647)BT.656-like 像素流 | 30 fps,640×480,MIPI byte clock 谐波 |
| 信道模型 | 像素 → byte clock 谐波 → IQ 基带 | 加性高斯噪声 + 多径 |
| 解调链 | 复数 IQ → 幅度 → 抽取 | 抽取因子 8 |
| 帧同步 | 自相关搜索 + 滞后阈值 | 与论文 §4.2 对齐 |
| 重建质量 | 与源图像 SSIM | **~0.98** |

输出文件位于 `simulation/output/`:`source_image.png`、`reconstructed.png`、`simulation_result.png`(三幅一组对比图)。

### §X.1.2 HDMI TEMPEST 扩展(候选人原创,论文方法泛化验证)

文件 `simulation/hdmi_simulation.py`(423 行)证明:**论文方法不是 EM Eye 专用工具,而是一个通用的 EM 侧信道重建平台**。这一点非常重要,它把本提案从"复现工作"提升到"平台工作":

| 参数 | EM Eye 场景 | HDMI TEMPEST 场景 |
|------|-------------|--------------------|
| 帧率 | 30 fps | **60 fps** |
| 像素时钟 | 12 MHz MIPI byte clk | **148.5 MHz**(1080p60 标称) |
| 同步信号 | 隐式(行长度推断) | **显式 H/V_SYNC** |
| 分辨率 | 640×480 | 1080p 缩到 **160×90** |
| 重建 SSIM | ~0.98 | **0.9907** |
| 重建 Correlation | — | **0.9976** |
| 端到端运行时间 | — | **1.2 s** |

输出 `simulation/output/hdmi_simulation_result.png`。这份扩展直接支撑本提案 Phase 4 "多模态侧信道" 路线图(power line 不局限于摄像头 EM Eye,可以一并覆盖 HDMI 视频泄漏)。

### §X.1.3 LDSDR → 主机 TCP 网络管线 demo

文件 `simulation/network_demo.py`(405 行):Python 模拟 FPGA 加速器输出 + TCP 传输 + 主机端重建,**主机侧代码全部预先验证完毕**,Phase 2 真硬件 bring-up 时只需要把 Python mock 换成真 socket。输出 `network_demo_source.png` 与 `network_demo_reconstructed.png` 已生成。

> 这条 demo 与 §X.5 的 PS 用户态 TCP forwarder 骨架协议兼容(同一帧头格式 + 同一 byte order),Phase 2 W2 即可对接。

---

## §X.2 FPGA 加速器 RTL 与单元测试

### §X.2.1 RTL 模块清单

| 文件 | 行数 | 功能 | DSP/BRAM |
|------|------|------|----------|
| `fpga_accel/rtl/magnitude_jpl.v` | 117 | JPL 近似幅度 \|I+jQ\| ≈ α·max + β·min | 0 / 0 |
| `fpga_accel/rtl/cic_decimator.v` | 86 | 1 阶 CIC boxcar 抽取(8x) | 0 / 0 |
| `fpga_accel/rtl/frame_sync.v` | 142 | 帧同步 FSM(平均 + 滞后阈值) | 0 / 1 |
| `fpga_accel/rtl/emeye_accel_top.v` | 282 | 顶层 + 双通道 + AXI-Stream FIFO | 0 / 0 |
| **RTL 小计** | **627** | | **0 DSP** |

`magnitude_jpl.v` 的核心是 **JPL 系数 0.375 = 1/4 + 1/8 推导**,这意味着幅度计算可以用 2 次右移 + 1 次加法完成,**完全无乘法器**:

```verilog
// magnitude_jpl.v 核心片段(伪)
wire [W-1:0] max_ab = (abs_i > abs_q) ? abs_i : abs_q;
wire [W-1:0] min_ab = (abs_i > abs_q) ? abs_q : abs_i;
// α ≈ 1.0, β = 0.375 = 0x60 in Q8 — 用移位实现
wire [W+1:0] mag = max_ab + (min_ab >> 2) + (min_ab >> 3);
```

### §X.2.2 单元测试结果(Icarus Verilog 13.0)

| Testbench | 文件 | 用例 | 结果 | 关键指标 |
|-----------|------|------|------|----------|
| `tb_magnitude_jpl` | sim/tb_magnitude_jpl.v(177 行) | 60 | **60/60 PASS** | 平均误差 **4.29%**,峰值 **6.80%**(JPL 规格内) |
| `tb_cic_decimator` | sim/tb_cic_decimator.v(222 行) | 11 | **11/11 PASS** | 抽取因子准确,无样本溢出 |
| `tb_frame_sync` | sim/tb_frame_sync.v(176 行) | 5 | **5/5 PASS** | 正确触发 `frame_start`,正确忽略短 blanking |
| `tb_emeye_accel` | sim/tb_emeye_accel.v(222 行) | 顶层 | **PASS** | 1156 AXI-Stream 输出,4 个 `frame_starts`,零样本丢失 |

`tb_emeye_accel` 在仿真期发现并修复了一个**真实 RTL bug**:顶层 round-robin 输出无缓冲导致样本丢失。修复方案是加 pending buffer + 优先级回退。这一条单独足以证明候选人不是"跑通即提交",而是用 testbench 兜真问题。

### §X.2.3 设计推导文档

`fpga_accel/doc/fpga_derivations.md`(529 行)系统记录了 7 类公式推导:

1. JPL 系数 0.375 = 1/4 + 1/8 误差界推导;
2. 1 阶 CIC sinc 频响零点位置(1/2/3/4 MHz @ Fs=8 MHz);
3. 帧同步 FSM 滞后阈值分析;
4. 流水线时延预算(**最优 7 cycle / 最坏 14 cycle**);
5. 资源预估(目标 ~600 LUT / 476 FF / 1 BRAM / 0 DSP — 见 §X.3 实测对比);
6. 跨时钟域转换的 metastability 风险点;
7. 7 个学长可能追问的 Q&A 自查清单(`Why JPL?`、`Why 1 阶 CIC?`、`Why no DSP?` 等)。

---

## §X.3 Vivado 工程化与真目标 bitstream 生成

> **目标器件:`xc7z010clg400-2`(LDSDR rev2.1 真硬件)**。不是 PlutoSDR 衍生 z020,这一点候选人专门核对过 LDSDR 原理图。

### §X.3.1 完整流程时间线

| 阶段 | 状态 | 时间戳 |
|------|------|---------|
| synth_2(z010 license 获取) | ✓ | 2026-05-13 23:17 |
| opt_design | ✓ | DRC **0 errors** |
| place_design | ✓ | — |
| route_design | ✓ | — |
| write_bitstream | ✓ | 2026-05-13 23:24,`Bitgen Completed Successfully` |
| **bitstream 产物** | `bitstream/ldsdr_2tr_emeye.bit` | 2.0 MB |
| **MD5(固定)** | `01a664a91e77f5477190d4f50a6de2a6` | |

全流程 **7 分钟**,在本地 Vivado 中无 license 冲突跑完。

### §X.3.2 XC7Z010 资源利用率实测

| 资源 | 已用 | 总量 | 占比 | 备注 |
|------|------|------|------|------|
| Slice LUT | 2,420 | 17,600 | **13.75%** | 86%+ 余量 |
| LUT as Logic | 2,116 | 17,600 | 12.02% | |
| LUT as Memory | 304 | 6,000 | 5.07% | |
| Slice Register (FF) | 4,074 | 35,200 | **11.57%** | |
| F7 Mux | 84 | 8,800 | <1% | |
| F8 Mux | 32 | 4,400 | <1% | |
| **DSP** | **0** | 80 | **0%** | JPL 完全无乘法器 |
| BRAM | 1 | 60 | 1.67% | 平均窗口环形缓冲 |

**关键结论**:Phase 3 多频段融合(候选人提案中第 3 章 §3.4 路线图)需要至多再加 3-4 路并行处理通道,**当前 86%+ 资源余量完全 cover 得住**。这是本提案"多频段融合可行"这条 claim 的硬证据。

### §X.3.3 时序结果(诚实分级披露)

| 时钟域 | WNS | 状态 | 备注 |
|--------|------|------|------|
| `clk_fpga_0`(8 MHz,emeye_accel 域) | **+3.05 ns** | ✓ 满足 | 候选人新加电路时序全部 clean |
| `rx_clk → clk_fpga_0`(跨时钟域) | **−2.985 ns** | ◐ 123 failing endpoints | **原 ad9361 模板就有的问题**,与 emeye_accel 无关 |

诚实披露:跨时钟域 WNS 负值不是候选人 RTL 引入的,是 LDSDR_2TR 模板把 `rx_clk` 直接打到 AXI 寄存器读侧的历史遗留。Phase 1 W1 计划的缓解措施有两条,任选其一即可:

- **方案 A**:`set_false_path -from [get_clocks rx_clk] -to [get_clocks clk_fpga_0]` + 加 2-FF 同步器;
- **方案 B**:在跨域路径上插 async FIFO(Xilinx FIFO Generator IP)。

候选人评估认为方案 A 更轻量,因为 AXI 寄存器读侧本来就只要求最终一致性,无严格采样关系。

### §X.3.4 Bitstream → BIN 后处理工具

文件 `bitstream/bit_to_bin.py`(53 行,纯 Python 无外部依赖)。它实现:

1. 找到 Xilinx `.bit` 文件里的 sync word `0xAA995566`;
2. 把后面所有 word **32-bit byte swap**(因为 Linux `fpga_manager` 接受 big-endian 字流);
3. 输出 raw `.bin` 给 `/sys/class/fpga_manager/fpga0/firmware` 接口。

产物 `bitstream/ldsdr_2tr_emeye_safe.bin`,MD5 `b294f2a3ed77adffc3bebaadb6c4e538`。

---

## §X.4 真 LDSDR 板烧录与 AD9361 RF 链路实测

> 这一节是本章的"杀手锏"。Phase 0 阶段就已经把 bitstream 真烧进 LDSDR,并且让 AD9361 在 EM Eye 论文的真实频点上跑起来了。

### §X.4.1 板级环境

| 项目 | 实测值 |
|------|--------|
| 板卡 | LDSDR rev2.1(XC7Z010 + AD9361) |
| 网络 | 千兆 GbE → 本机 LAN,IP **192.168.3.10** |
| 登录 | SSH `root/analog`(沿用 PlutoSDR 默认凭据) |
| 板上系统 | **Linux 5.15.0** + ARMv7l + PlutoSDR Rev.A 标准 rootfs |
| 烧录接口 | `/sys/class/fpga_manager/fpga0/firmware`(write `.bin` filename) |

### §X.4.2 烧录验证(2026-05-14 上午)

执行 sysfs 烧录后系统返回与 dmesg 全部清晰:

```
# echo ldsdr_2tr_emeye_safe.bin > /sys/class/fpga_manager/fpga0/firmware
WRITE_OK
# dmesg | tail -2
[ ... ] fpga_manager fpga0: writing ldsdr_2tr_emeye_safe.bin to Xilinx Zynq FPGA Manager
[ ... ] fpga_manager fpga0: state=operating
```

烧录后稳定性验证清单:

- ✓ FPGA Manager `state = operating`;
- ✓ 千兆 MAC 没断,SSH 连接保持;
- ✓ 板子稳定 30+ 分钟无 kernel oops;
- ✓ dmesg AD9361 错误 **零条**。

### §X.4.3 AD9361 RF 链路验证(204 MHz EM Eye 频点)

候选人**没有停在"烧录成功"这一步**,而是继续把 AD9361 配到 EM Eye 论文方法关心的 byte-clock 谐波频段并真实接收 RF:

| AD9361 参数 | 值 | 备注 |
|-------------|-----|------|
| ENSM mode | `fdd` | 工作模式 |
| 默认 RX_LO | 2.4 GHz | 上电默认 |
| **配置后 RX_LO** | **204 MHz** | EM Eye byte-clock 谐波 |
| 采样率 SR | **8 MSPS** | 与 §X.2 CIC 抽取参数一致 |
| RX Gain | 50 dB | manual gain control |
| **RSSI** | **93.75 dB** | 真实 RF 接收信号强度 |

IIO buffer 采集 **16 KB 真实 IQ 数据**(signed 12-bit ADC 输出),前 16 字节例:

```
f0ff d5ff e4ff ffff ebff 1f00 ecff e1ff ...
```

非零,典型空气接收 baseline 噪声+信号(signed 12-bit little-endian:`0xfff0` → −16,`0xffd5` → −43,等等)。**这意味着 RX path 是真的导通的,不是空采**。

工具链全部用 `iio_attr` + sysfs 直接读写,无需 libiio C API 介入,Phase 1 直接复用。

### §X.4.4 这一步对提案的意义

把这一步在提案阶段做完,意味着 **Phase 1 W1 的硬件 bring-up 风险被前置消除**:LDSDR 进 lab 当天就可以直接进 Phase 1 Day 3(emeye_accel IQ tap 接线),省 1-2 周。

---

## §X.5 Phase 2 准备文档(提前完成)

为了让 Phase 2 不在文档阶段卡壳,候选人已经写完了两份 451 + 251 + 394 = **1,096 行**的工程预案。

### §X.5.1 Phase 2 IQ Tap 方案

`fpga_accel/doc/phase2_iq_tap.md`(451 行):

- BD(Block Design)中把 `axi_ad9361` ADC AXI-Stream 直接 **tap 到 `emeye_accel_top`** 的两套方案对比:
  - **方案 A**(顶层手动接):优点直观,缺点改动顶层 verilog,工程文件混乱;
  - **方案 B**(BD 内 IP block 包装):优点工程整洁,缺点要写 IP packaging。候选人推荐方案 B。
- **5 项待验证清单**(Day 1-2 必做):时钟域、stream 位宽、tready 反压、空 idle 处理、reset 序列;
- Phase 2 第一周 **Day by Day 任务拆解**(D1: tap → D2: 单通 → D3: 双通 → D4: 同步触发 → D5: 联调)。

### §X.5.2 Phase 2 PS 用户态 TCP Forwarder

`fpga_accel/doc/phase2_tcp_forwarder.md`(251 行)+ `phase2_tcp_forwarder.c`(394 行 C 骨架):

- **AXI-DMA S2MM 寄存器定义**全部标注 Xilinx **PG021** 出处(MM2S_DMACR / SA / LENGTH / S2MM_DMASR 等);
- 关键设计点:
  - **UIO + mmap** 用户态访问 AXI 寄存器(不写 kernel driver);
  - **ping-pong buffer**(2×4MB)避免 DMA 等 socket;
  - **TCP_NODELAY + SO_SNDBUF=4MB** 优化吞吐;
  - 跟 `simulation/network_demo.py` 客户端 **协议兼容**(同一 32-byte 帧头 + little-endian payload)。

代码骨架例(节选自 `phase2_tcp_forwarder.c`):

```c
// AXI-DMA S2MM 寄存器 offset(PG021 §2.2)
#define S2MM_DMACR     0x30
#define S2MM_DMASR     0x34
#define S2MM_DA        0x48
#define S2MM_LENGTH    0x58

// ping-pong DMA buffer
static uint8_t *buf[2];   // 2 × 4MB,bus-aligned
static int active = 0;

void dma_kick(int idx) {
    write32(s2mm_base + S2MM_DA,     bus_addr[idx]);
    write32(s2mm_base + S2MM_LENGTH, BUF_LEN);
}
```

Phase 2 W2 主机侧只要把 `simulation/network_demo.py` 的 mock socket 接到这个 forwarder,管线就闭环。

---

## §X.6 工作量与产物清单

### §X.6.1 产物清单总表

| 类别 | 文件 | 行数 / 大小 | 状态 |
|------|------|-------------|------|
| **仿真** | `simulation/emeye_simulation.py` | 501 行 | ✓ |
| | `simulation/hdmi_simulation.py` | 423 行 | ✓ |
| | `simulation/network_demo.py` | 405 行 | ✓ |
| | `simulation/output/*.png` | 8 张图 | ✓ |
| **RTL 设计** | `fpga_accel/rtl/magnitude_jpl.v` | 117 行 | ✓ |
| | `fpga_accel/rtl/cic_decimator.v` | 86 行 | ✓ |
| | `fpga_accel/rtl/frame_sync.v` | 142 行 | ✓ |
| | `fpga_accel/rtl/emeye_accel_top.v` | 282 行 | ✓ |
| **Testbench** | `fpga_accel/sim/tb_magnitude_jpl.v` | 177 行 | ✓ 60/60 PASS |
| | `fpga_accel/sim/tb_cic_decimator.v` | 222 行 | ✓ 11/11 PASS |
| | `fpga_accel/sim/tb_frame_sync.v` | 176 行 | ✓ 5/5 PASS |
| | `fpga_accel/sim/tb_emeye_accel.v` | 222 行 | ✓ PASS |
| **设计文档** | `fpga_accel/doc/fpga_derivations.md` | 529 行 | ✓ |
| | `fpga_accel/doc/phase2_iq_tap.md` | 451 行 | ✓ |
| | `fpga_accel/doc/phase2_tcp_forwarder.md` | 251 行 | ✓ |
| | `fpga_accel/doc/phase2_tcp_forwarder.c`(骨架) | 394 行 | ◐ |
| **Bitstream** | `bitstream/ldsdr_2tr_emeye.bit` | 2.0 MB,MD5 `01a664a9...d4f50a6de2a6` | ✓ |
| | `bitstream/ldsdr_2tr_emeye_safe.bin` | 2.0 MB,MD5 `b294f2a3...adb6c4e538` | ✓ |
| | `bitstream/bit_to_bin.py` | 53 行 | ✓ |
| **总计** | 工程文件 ~20 份 | **~6,000 行** | |

### §X.6.2 状态分级图例

- ✓ **已完成**:代码存在、可运行/可综合,有可重现的实测结果;
- ◐ **部分完成**:骨架/接口/方案已定,Phase 1-2 W1 内完成最后接线;
- ○ **Phase 1 计划**:尚未动工,但写在 §X.3.3 的 mitigation 或 §X.5 的 Day by Day 任务里。

---

## §X.7 这些工作支撑的提案 claim 验证

本章不是孤立的"我做了什么"列表,**每一份产物都对应提案正文里的一条工程论断**。下表是对照清单:

| 提案 claim(本章节正文章号) | 支撑证据(本章节号) | 证据强度 |
|------------------------------|----------------------|----------|
| 第 2 章 §2.3 CT 选型 + 多频段融合可行 | §X.3.2 资源利用率 13.75% LUT,Phase 3 多频段 86% 余量充足 | **硬实测** |
| 第 2 章 §2.4 加速器纯整数运算 + 零 DSP | §X.2.1 magnitude_jpl 仅移位+加,§X.3.2 DSP 实测 = 0 | **硬实测** |
| 第 2 章 §2.5 跨时钟域风险已识别 + 已有缓解 | §X.3.3 WNS −2.985 ns + Phase 1 W1 双方案 | **硬实测 + 明确计划** |
| 第 2 章 §2.6 JPL 误差在可接受区间 | §X.2.2 平均误差 4.29% / 峰值 6.80% | **硬实测** |
| 第 3 章 §3.1 EM Eye 论文方法已掌握 | §X.1.1 Python 仿真 SSIM 0.98 | **硬实测** |
| 第 3 章 §3.4 平台可泛化到 HDMI TEMPEST | §X.1.2 HDMI 仿真 SSIM 0.9907 / Corr 0.9976 | **硬实测** |
| 第 3 章 §3.5 LDSDR 已可控,Phase 1 风险低 | §X.4 真板 SSH + 烧录 + RF RSSI 93.75 dB | **硬实测** |
| 第 3 章 §3.6 AD9361 可调到 EM Eye 频段 | §X.4.3 RX_LO 配 204 MHz,16 KB IQ 真实采集 | **硬实测** |
| 第 4 章 §4.1 网络管线主机侧无 blocker | §X.1.3 network_demo.py 全链路 + §X.5.2 PS 端骨架 | **硬实测 + 骨架就绪** |
| 第 4 章 §4.2 Phase 2 Day-by-Day 不卡壳 | §X.5.1 IQ tap 方案 + 5 项待验证清单 | **方案就绪** |

---

## §X.8 小结

总结一句:**本提案不是规划书,是已经动工的工程报告**。Phase 0 的关键工程风险(论文方法理解、RTL 可综合性、目标器件资源容量、真板可控性、RF 链路在论文频点的可用性、Phase 2 主机管线协议)在提案提交之前已被逐一前置消除。

候选人请求 RA 录用后,**Phase 1 W1 第 1 天可以直接进入 emeye_accel 与 axi_ad9361 IQ tap 的真板联调**,而不是再花 1-2 周做 bring-up。

— 完 —
