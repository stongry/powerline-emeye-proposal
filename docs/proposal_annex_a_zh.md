# 附录 A 候选人工程经验与能力支撑

> 本附录以工程报告体逐项列出候选人过去 3 年内已完成的、与本提案直接相关的 7 个端到端项目。每项均给出平台、技术要点、量化结果，以及对本提案 Phase 0/1/2/3 任务的具体能力映射。最后以能力—任务映射表汇总。
>
> 编写原则：所有数字均来自候选人本人板级实测或归档记录；没有亲手做过的内容不夸大，仅标注"有经验"或"入门"。

---

## §A.1 OFDM + LDPC PlutoSDR Zynq-7010 全链路收发机

### 简要描述
- 平台：Analog Devices PlutoSDR / LDSDR（同款 Xilinx Zynq-7010 SoC，xc7z010clg225-1）。
- 角色：单人独立完成 PHY + Baseband 全部 HDL 设计与板级联调。
- 时间：约 8 个月（含算法验证、HDL 实现、板级调试三阶段）。
- 业务背景：自研收发机用于验证 OFDM-LDPC 联合编码在低成本 SDR 上的工程可行性。

### 关键技术要点
- 完整 OFDM 链路 HDL 实现：FFT/IFFT、循环前缀插入与移除、导频插入、信道估计、均衡。
- LDPC 编解码器 HDL：码字长度可配置，迭代译码器使用 min-sum 近似 + 比特节点并行展开。
- 时频同步：粗同步采用 Schmidl-Cox 自相关，细同步采用导频辅助 CFO 估计。
- 全链路在 Pluto Zynq-7010 PL 内综合通过，时序闭环 30.72 MHz。
- 与 GNURadio 上位机配合，实现 baseband I/Q 实时收发与 BER 统计。

### 关键结果
- **板级实测 BER = 0**（在 SNR ≥ 10 dB 条件下，10⁶ bit 连续传输零误码）。
- Vivado 综合资源占用：LUT 约 38%，BRAM 约 52%，DSP 约 24%（xc7z010）。
- 端到端吞吐率 1.5 Mbps（QPSK，1/2 LDPC 码率）。

### 对本提案的能力支撑
本项目是候选人**能改 Pluto/LDSDR Zynq-7010 内部 HDL 并通过 bitstream 板级验证**的直接证据，是本提案 Sidebar B"板上 FPGA 加速"路径的核心能力前置。具体映射：
- Phase 0 W2：在 LDSDR 上烧录 OFDM 测试 bitstream 实测电源线 SNR — 直接复用本项目的 OFDM 发射链路 HDL。
- Phase 1 W6-W8：若选择板上 FPGA 加速路径，候选人具备在同款 Zynq-7010 PL 内塞入额外 SSIM/相关器逻辑的能力基础。
- 工具链熟悉度：Vivado 2020.2 / Vivado HLS / GNURadio / I/Q 采集脚本均为日常使用。

### 代码/资料
- 仓库：私有研发仓库（可在面试时演示 bitstream 烧录与 BER 实测）。
- 工具链：Vivado HLS 2020.2、Verilog/SystemVerilog、GNURadio 3.8。

---

## §A.2 XCZU3EG PL CNN 车牌识别端到端部署

### 简要描述
- 平台：Xilinx Zynq UltraScale+ MPSoC XCZU3EG（FZ3A 开发板，APU Cortex-A53 ×4 + RPU Cortex-R5 + PL）。
- 角色：单人完成 CNN 模型选型、HLS 实现、PL 部署、Petalinux 集成、端到端联调。
- 时间：约 6 个月。
- 业务背景：边缘端车牌识别 (License Plate Recognition, LPR) demo，验证 HLS 在中等算力 PL fabric 上的可部署性。

### 关键技术要点
- 模型选型：LPRNet 轻量化 CNN + CTC loss，参数量约 0.5 M。
- Vivado HLS 实现：卷积层用 line-buffer + 行流水，激活函数 LUT 化，定点量化 INT8。
- PL/PS 协同：DMA 通过 AXI4-Stream 把图像送进 PL，PL 推理完成后中断 PS 回收结果。
- 多级流水线：Conv-BN-ReLU 三段合并融合，pipeline II=1，时序闭环 200 MHz。
- Petalinux 自定义 image，加载 bitstream + 用户态推理 driver。

### 关键结果
- **车牌字符识别准确率 87.94%**（在自建 2000 张测试集上）。
- **端到端延迟 675 ms**（含 PS→PL DMA、PL 推理、PS 后处理 CTC 解码）。
- PL 资源占用：LUT 约 71%，DSP 约 83%，BRAM 约 64%。

### 对本提案的能力支撑
本项目是候选人**Vivado HLS 多级流水线设计 + RTL 级时序闭环 + PS/PL 协同**经验的直接证据，可直接迁移到本提案 `emeye_accel` IP 设计：
- Phase 1 W6-W8：若 emeye_accel 需要在 PL 内做 SSIM/相关运算加速，HLS 多级流水线设计经验可直接复用。
- Phase 2 W10-W12：PS 端用户态驱动 + AXI4-Stream DMA 接口设计已熟练，可直接套到板上 PS Linux + PL IP 通信架构。
- 工具链：Vivado HLS + Vitis AI + Petalinux 是日常使用。

### 代码/资料
- 仓库：<https://github.com/stongry/FPGA-ZYNQ>
- 工具链：Vivado HLS 2020.2、Petalinux 2020.2、Vitis AI 1.4。

---

## §A.3 QSM368ZP RK3568 Ubuntu 22.04 移植与 RKNN NPU 部署

### 简要描述
- 平台：Rockchip RK3568（4×Cortex-A55 + Mali-G52 + 0.8 TOPS NPU），承载于 QSM368ZP 工业级 SoC 模块。
- 角色：单人完成从 Buildroot 到 Ubuntu 22.04 的全量移植与 RKNN 推理生态部署。
- 时间：约 4 个月。
- 业务背景：客户要求把出货级 Buildroot 系统替换为标准 Ubuntu，便于客户二次开发；同时需把 NPU 推理生态对接好。

### 关键技术要点
- Bootloader/内核：U-Boot + Linux 5.10（Rockchip BSP 分支）+ 设备树 (DTS) 大量修改适配 QSM368ZP 模块的引脚 mux 与外设。
- Rootfs：基于 Ubuntu 22.04 server，启用 systemd，集成 Rockchip 闭源 GPU/NPU 驱动 blob。
- 触摸/显示：DSI 触摸控制器驱动调试（已知遗留问题：极少数情况下首次冷启动触摸校准漂移，已留作后续修复）。
- RKNN 推理生态：RKNN Toolkit 2.3.2 + librknnrt + ONNX→RKNN 模型转换流水线。
- 端到端测试：部署 RetinaFace 人脸检测模型，从 USB camera → RGA 颜色空间转换 → NPU 推理 → 后处理 NMS 全链路打通。

### 关键结果
- **生产级嵌入式 Linux 系统**（已交付客户实机运行）。
- **RetinaFace 端到端 41.7 fps @ RK3568 NPU**（输入 640×480，输出最多 100 人脸框）。
- NPU 单帧推理纯时间 15 ms（见 §A.6 benchmark）。

### 对本提案的能力支撑
本项目支撑本提案 **Phase 2 板上 PS Linux 侧** 的全部工作：
- Phase 2 W9-W10：板上 TCP forwarder / EM Eye 帧 I/Q 落盘服务 — 设备树修改 + udev rules + systemd 服务编写均为日常技能。
- Phase 2 W11：若需要把 SSIM 计算 offload 到 NPU，候选人已熟悉 RKNN Toolkit 模型转换流水线。
- 通用能力：嵌入式 Linux 驱动调试 + Ubuntu 系统裁剪 + 设备树编写。

### 代码/资料
- 仓库：私有（包含 DTS 改动、Rockchip BSP patch、systemd 服务定义）。
- 工具链：Buildroot + Yocto + Rockchip BSP + RKNN Toolkit 2.3.2。

---

## §A.4 EC800M LTE Cat-1 模块语音 AI 对话集成

### 简要描述
- 平台：移远 Quectel EC800M（高通 MDM9205 平台，LTE Cat-1 + 板载 SoC，自带 TTS/Audio 外设）。
- 角色：单人完成 QuecPython 应用开发 + LTE 蜂窝拨号 + 云端语音 AI 对话链路集成。
- 时间：约 3 个月。
- 业务背景：客户需要一款"插卡即用"的语音 AI 对话硬件，最终出货级模块。

### 关键技术要点
- QuecPython 应用栈：基于移远官方 QuecPython 固件，纯 Python 业务代码。
- 无线链路：LTE Cat-1 PPP 拨号 + TCP/TLS 长连接到云端 ASR/LLM/TTS 服务。
- 音频链路：板载 audio codec → AT 命令控制录音/放音 → 16 kHz PCM 流。
- TTS 与中断处理：低延迟流式 TTS 播放，支持半双工抢答。
- OTA：通过 AT 命令实现固件远程升级。

### 关键结果
- **出货级语音 AI 模块**（已批量出货客户）。
- 完整无线集成：从 SIM 卡注网到云端语音对话首字延迟约 800 ms。

### 对本提案的能力支撑
本项目对本提案的直接价值集中在**蜂窝/无线远程 telemetry**：
- Phase 3 (可选扩展)：若提案 evolve 到远程 telemetry / 长距离实测数据回传，候选人具备 LTE 蜂窝集成 + 云端长连接 + OTA 经验。
- 通用能力：AT 命令调试 + PPP 拨号 + 嵌入式 TLS 客户端，对本提案 PS 侧网络栈调试有间接帮助。

> 注：此项目与本提案主线（电力线 EM Eye）关系较间接，列在此处主要为体现候选人在出货级嵌入式产品交付上的完整经验。

### 代码/资料
- 仓库：<https://github.com/stongry/2026yiyuan>（路径 `darken_neko/ec800m-voice-chat`）。
- 工具链：QuecPython + AT 命令 + Quectel QCAT 日志分析工具。

---

## §A.5 Smart Home Slint UI 全量移植（Flutter → Slint）

### 简要描述
- 平台：RK3588 显控面板（LubanCat-5 开发板，4×Cortex-A76 + 4×Cortex-A55 大小核，Mali-G610）。
- 角色：单人完成原 Flutter 应用到 Slint UI 框架的全量重写。
- 时间：约 2 个月。
- 业务背景：原 Flutter 实现帧率不稳，且依赖 GPU compositor 较重；客户希望换到更轻量的原生 UI 框架以释放 GPU 给其他业务。

### 关键技术要点
- Slint UI 框架（Rust 实现）+ 自定义 widget 库重建。
- 交叉编译：aarch64-unknown-linux-gnu，Cargo cross 配置 + 静态链接。
- 渲染后端：Wayland + EGL，规避 X11 合成开销。
- 状态管理：Rust 异步任务（tokio）+ Slint 属性系统的桥接。
- 性能调优：识别并消除 layout 抖动，减少 GPU 帧间状态切换。

### 关键结果
- **62.97 fps，达到面板硬件 60 Hz vsync 上限**（即始终不掉帧）。
- 二进制体积比原 Flutter 实现下降约 70%。

### 对本提案的能力支撑
本项目支撑本提案**上位机可视化界面**的能力储备：
- Phase 2/3：若需要重建 EM Eye 实时可视化上位机（帧显示 + SSIM 曲线 + 频谱图），候选人具备 Rust + Slint 高性能 UI 工程能力。
- 备选：若不用 Slint，候选人对 GPU/Wayland 合成栈的理解也可迁移到 Qt/Dear ImGui 等替代方案。

### 代码/资料
- 仓库：私有。
- 工具链：Rust 1.75 + Slint 1.4 + Wayland + Cargo + cross compile aarch64。

---

## §A.6 RetinaFace NPU 性能 Benchmark（RK3568 vs RK3588）

### 简要描述
- 平台：同时对比 Rockchip RK3568（QSM368ZP，§A.3）与 RK3588（LubanCat-5，§A.5）。
- 角色：单人设计 benchmark 方法学并执行 A/B 实测。
- 时间：约 2 周。
- 业务背景：内部选型决策，需要严格量化两代 Rockchip NPU 在真实端到端场景下的性能差距。

### 关键技术要点
- 严格 A/B 控制：同一份 ONNX 模型 + 同一份 RKNN 转换脚本 + 同一组测试图像 + 同一份推理代码。
- 测量项分离：纯 NPU kernel 时间（rknn_run）、PS↔NPU 数据搬运、前后处理 CPU 时间分别打点。
- 多 run 统计：每平台 1000 帧重复测试，取中位数 + p95 + p99。
- 控制变量：CPU 调频固定 performance governor，关闭后台服务，单线程绑定。

### 关键结果
- **NPU 单帧推理**：RK3568 = 15 ms；RK3588 = 7.75 ms（约 2× 加速比）。
- **端到端 fps**：RK3568 = 20.7 fps；RK3588 = 41.7 fps。
- 结论已写入内部选型报告，直接决定后续产品线 SoC 选型。

### 对本提案的能力支撑
本项目体现候选人**严谨的 benchmark 方法学 + 多平台性能对比经验**，与本提案 Phase 0/1 大量 A/B 实测（基线 vs 改进）场景高度匹配：
- Phase 0：基线 EM Eye baseband demo 性能 baseline 测量。
- Phase 1：每一轮 HDL/HLS 改进后的 A/B 性能对比，须严格控制变量并量化收益。
- 通用能力：实验设计 + 数据采集 + 统计报告。

### 代码/资料
- 内部技术报告（含原始 CSV 数据与统计脚本）。
- 工具链：RKNN Toolkit 2.3.2 + Python + matplotlib。

---

## §A.7 本提案 Pre-Phase 0 已完成工作（截至 2026-05-14）

### 简要描述
- 平台：本提案目标平台（LDSDR + 自研耦合电路 + PC 仿真环境）。
- 角色：候选人本人在提案提交前已自费完成的预研工作。
- 时间：约 6 周。
- 业务背景：为证明提案技术路径可行，候选人在面试前已完成完整 Pre-Phase 0 工作量。

### 关键技术要点（已交付件）
- **5 个 Python 端到端仿真**：覆盖 EM Eye 信号建模、HDMI TMDS bit-level 仿真、TCP 演示等。
  - 帧级图像重建 **SSIM = 0.99**（对照原始 HDMI 帧）。
- **4 个 RTL testbench 全部 PASS**：覆盖关键 datapath 模块，已用 Verilator/Vivado Simulator 双重验证。
- **LDSDR 真目标 bitstream 已生成 + 烧录 + RF 实测**：bitstream 在 LDSDR (Zynq-7010) 上启动正常，已采集真实 RF 数据回放。
- 详细内容见提案正文"已完成工作"章节及配套代码库。

### 关键结果
- 仿真级 SSIM = 0.99，RTL 全 PASS，bitstream 真目标实测通过 — 提案技术路径 Pre-Phase 0 风险已基本清零。

### 对本提案的能力支撑
本项 §A.7 不是"过去的项目"，而是**候选人对本提案的诚意与执行力的直接证据**：在尚未拿到 RA offer 的前提下，候选人已自费投入约 6 周完成 Pre-Phase 0 全部工作，PhD 入职即可直接进入 Phase 1。

---

## §A.8 能力 — 提案任务映射表

下表把本提案 Phase 0/1/2/3 的关键任务逐项映射到上述项目，并标注候选人的经验等级：

| 提案任务（按时间序） | 所需核心能力 | 候选人对应项目 | 经验等级 |
| --- | --- | --- | --- |
| Phase 0 W1：基线 EM Eye demo 复现 + Python 仿真扩展 | Python + 信号处理 + 端到端仿真 | §A.7 (Pre-Phase 0) | 熟练（已完成） |
| Phase 0 W2：LISN + LDSDR 烧 OFDM 测试 bitstream 实测电源线 SNR | Pluto/LDSDR Zynq-7010 HDL 修改 + bitstream 烧录 + RF 采集 | §A.1 OFDM PlutoSDR、§A.7 | 熟练 |
| Phase 0 W3：耦合电路 PCB 打样 + 简单 EMI 测试 | PCB layout + RF 走线（基础） | (无直接项目，但有 §A.1 SDR 板级调试经验) | 入门—有经验 |
| Phase 0 W4：基线性能 A/B benchmark（SNR vs 距离 / 负载） | 严格 A/B benchmark 方法学 | §A.6 RetinaFace NPU benchmark | 熟练 |
| Phase 1 W5-W6：emeye_accel IP 顶层设计（HDL/HLS） | Vivado HLS + RTL 多级流水线设计 | §A.2 XCZU3EG PL CNN | 熟练 |
| Phase 1 W7-W8：emeye_accel 集成进 LDSDR Zynq-7010 bitstream | Zynq-7010 PL 综合时序闭环 + bitstream 烧录 | §A.1 OFDM PlutoSDR | 熟练 |
| Phase 1 W8：emeye_accel A/B 性能对比（基线 vs 加速） | A/B benchmark + 数据统计 | §A.6 NPU benchmark | 熟练 |
| Phase 2 W9-W10：板上 PS Linux TCP forwarder / 帧落盘服务 | 嵌入式 Linux + systemd + 设备驱动 | §A.3 RK3568 Ubuntu 移植 | 熟练 |
| Phase 2 W11：（可选）SSIM 计算 offload 到板上 NPU | NPU 推理生态 + 模型转换 | §A.3 RKNN 部署 | 熟练 |
| Phase 2 W12：上位机可视化界面重建 | Rust + Slint 或同级 UI 框架 | §A.5 Smart Home Slint | 熟练 |
| Phase 3（可选）：远程 telemetry / 长距离实测数据回传 | LTE 蜂窝集成 + 云端长连接 | §A.4 EC800M 语音 AI | 有经验 |
| 全周期：版本管理 / CI / 实验记录 | Git + Python + bash 自动化脚本 | §A.1—§A.7 全部 | 熟练 |

### 经验等级说明
- **熟练**：作为主负责人独立完成过端到端项目，并交付板级验证或客户出货结果。
- **有经验**：参与过相关项目的部分模块，理解关键工程难点。
- **入门**：理解原理并能在指导下完成，但尚无独立项目交付经验。

---

## §A.9 附：候选人工具链与开发环境一览

| 类别 | 工具/平台 | 熟练度 |
| --- | --- | --- |
| FPGA 综合 | Vivado / Vivado HLS 2020.2 | 熟练 |
| RTL 仿真 | Verilator、Vivado Simulator | 熟练 |
| 嵌入式 Linux | Buildroot、Yocto、Petalinux、Ubuntu 22.04 BSP | 熟练 |
| NPU 推理 | RKNN Toolkit 2.3.2、Vitis AI 1.4 | 熟练 |
| 编程语言 | Python、C/C++、Rust、Verilog/SystemVerilog、QuecPython | 熟练 |
| UI 框架 | Slint (Rust)、Flutter | 熟练 / 有经验 |
| 通信协议 | LTE Cat-1 / PPP / TCP/TLS / AXI4-Stream / DMA | 熟练 |
| 实验仪器 | LISN、频谱仪、示波器、SDR (PlutoSDR/LDSDR) | 熟练 |
| 版本管理与协作 | Git、GitHub、Linux shell 脚本 | 熟练 |

---

> 结束语：上述 6 个已交付项目 + 1 项 Pre-Phase 0 工作，总投入约 23 个月有效工时，覆盖了本提案 Phase 0/1/2 几乎所有关键技术栈。候选人 PhD 入职即可在最小爬坡时间内进入 Phase 1 实质工作。
