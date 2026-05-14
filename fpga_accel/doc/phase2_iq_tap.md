# Phase 2 草稿：真实 IQ Tap 方案

**状态**: 规划文档，Phase 2 第一周工作计划。所有标注 `[待验证]` 的条目必须在 LDSDR_2TR 工程打开后实测确认。

---

## 1. 背景与目标

当前 `ad9361_top.v` 中，`emeye_accel_top` 的输入接的是 test counter，不是真实 ADC 数据：

```verilog
.rx1_i  ($signed(test_cnt)),
.rx1_q  ($signed(~test_cnt)),
.rx1_valid (1'b1),
```

Phase 2 的核心目标是：**把 AD9361/AD9363 PHY 解串后的真实 IQ 样本 tap 到 `emeye_accel_top` 的输入**，让幅度累积帧从真实 RF 信号产生，而不是递增计数器。

---

## 2. 数据通路概念图

```
外部 LVDS 引脚 (rx_data_in_p/n[5:0])
         │
         ▼
  ┌─────────────────────────────────────────────────────┐
  │         axi_ad9361 IP (ADI Analog Devices)          │
  │                                                     │
  │  内部 LVDS 解串 → DDR 双沿采样 → 12-bit I/Q         │
  │                                                     │
  │  输出 (在 IP 内部,接到 BD 的 ADC AXI-Stream master): │
  │    adc_data_i0[15:0]  (或 12-bit,待确认)           │
  │    adc_data_q0[15:0]                               │
  │    adc_data_i1[15:0]  (RX2 通道)                   │
  │    adc_data_q1[15:0]                               │
  │    adc_valid_0, adc_valid_1                        │
  │    adc_clk            (→ ~100~200 MHz, 待确认)     │
  └─────────────────────────────────────────────────────┘
         │                         │
         ▼                         ▼
  axi_ad9361 AXI-Stream         axi_ad9361 AXI-Stream
  master port (到 PS FIFO)     [我们要 tap 的点]
                                   │
                                   ▼
                          axis_clock_converter
                          (adc_clk → emeye_clk 8 MHz)
                                   │
                                   ▼
                          emeye_accel_top
                          (rx1_i/q, rx2_i/q, rx1/2_valid)
                                   │
                                   ▼
                          m_axis_tdata/tvalid/tlast
                                   │
                                   ▼
                          axis_data_fifo (depth 1024)
                                   │
                                   ▼
                          axi_dma S2MM → DDR HP port
                                   │
                                   ▼
                          PS Linux 用户态 TCP forwarder
```

---

## 3. 已知约束与待验证清单

### 3.1 已知 (来自现有工程)

| 条目 | 数值 | 来源 |
|------|------|------|
| 目标器件 | xc7z010clg400-2 | LDSDR rev2.1 bitstream |
| emeye_accel 内部时钟 | `emeye_clk = spi_clk` (当前) | ad9361_top.v |
| emeye_accel 输入位宽 | 12-bit signed | emeye_accel_top.v 端口定义 |
| emeye_accel 采样率假设 | 8 MSPS | EM Eye 论文参数 |
| AD9363 最大 RX rate | ~61.44 MSPS (LVDS) | ADI 规格书 |

### 3.2 待验证 `[待验证]` — Phase 2 第一周 Day 1-2 必做

1. **`[待验证]` axi_ad9361 ADC Stream 端口名**
   - 可能是 `adc_data_i0`/`adc_data_q0`，也可能是 `m_axis_tdata`（AXI-Stream 打包格式）
   - **操作**: 打开 `LDSDR_2TR/design_1.bd`，找到 axi_ad9361 IP，在 Block Design 里展开 IP，查看 ADC 侧 master port 名称
   - 参考：ADI HDL 库 `library/axi_ad9361/axi_ad9361.v` 顶层端口 `adc_data_i0`、`adc_data_q0` 是并行输出，不是 AXI-Stream；真正的 stream 封装在 `util_ad9361_adc_fifo` 或 `axi_dmac` 前的 FIFO 层

2. **`[待验证]` 数据位宽: 12 还是 16 位，是否有符号扩展**
   - ADI IP 通常把 12-bit ADC 数据左对齐到 16-bit，低 4 位为 0（或右对齐，看配置）
   - **操作**: 在 IP 的 `.xci` 或 Vivado IP 配置界面查看 "ADC Data Width" 参数
   - 影响: 如果是 16-bit 左对齐，tap 到 emeye 时要 `adc_data_i0[15:4]` 取高 12 位

3. **`[待验证]` adc_clk 频率**
   - AD9363 以 8 MSPS 配置时，LVDS DDR 的 DATA_CLK 为 4 MHz（每沿一个 bit，6 bit per sample，共 12-bit = 3 个时钟周期，详见 ADI UG570）
   - 但 axi_ad9361 IP 内部 FIFO 输出侧的时钟可能是 100 MHz 或 200 MHz (与 Zynq FCLK 同步后的 adc_clk)
   - **操作**: 查看 BD 里 axi_ad9361 的 `adc_clk` 端口连接，追到时钟源

4. **`[待验证]` RX1/RX2 是否都有效**
   - LDSDR 硬件可能只焊了 RX1；RX2 即使 IP 有端口也可能是全零
   - **操作**: 查 LDSDR 硬件原理图，确认 AD9363 的 RX2A_N/P 是否接到了 FPGA

5. **`[待验证]` valid 信号的语义**
   - `adc_valid_0` 可能是 Level 信号（常高，表示流持续有效），也可能是脉冲（每 sample 一个脉冲）
   - **操作**: 仿真 axi_ad9361 IP 或阅读 ADI Wiki: https://wiki.analog.com/resources/fpga/docs/axi_ad9361

---

## 4. 修改方案对比

### 方案 A：最小改动 — 在 `ad9361_top.v` 顶层手动接

**核心思路**: 把 BD (system_wrapper) 内部的 `adc_data_*` 端口通过 "Make External" 暴露到顶层，然后在 `ad9361_top.v` 里直接接到 `emeye_accel_top`。

**优点**:
- 不需要修改 BD 内部连线，修改量最小
- `emeye_accel_top` 接口不变（保持并行 I/Q 输入），无需改 RTL
- 便于快速验证

**缺点**:
- 需要在 BD 里手动 "Make External" 多个端口，BD 端口数增加
- 跨时钟域处理（adc_clk vs emeye_clk）要在 `ad9361_top.v` 里手动加 synchronizer 或 FIFO
- 如果 BD 重新生成（Re-generate），手动 External 的端口可能丢失

**Vivado 操作步骤（方案 A）**:

```
1. 打开 LDSDR_2TR 工程 → 打开 design_1.bd
2. 找到 axi_ad9361 IP block
3. 展开 IP，找到 ADC 输出端口（adc_data_i0, adc_data_q0 等）
4. 右键 → Make External（每个端口单独操作，或批量选中）
5. 生成 BD Wrapper（右键 design_1 → Generate HDL Wrapper）
6. 在 system_wrapper.v (或 system_top.v) 新增端口声明
7. 在 ad9361_top.v 实例化 system_wrapper 时连接这些端口
8. 加 axis_clock_converter / 异步 FIFO 处理跨域
```

**`ad9361_top.v` 修改草稿（方案 A）**:

```verilog
// ─────────────────────────────────────────────────────────────
// Phase 2: 真实 IQ tap — 方案 A (暴露 BD 内部 ADC 信号)
// [待验证] 端口名以实际 BD 生成的 system_wrapper.v 为准
// ─────────────────────────────────────────────────────────────

// Step 1: 声明从 BD 暴露出来的 ADC 信号
// [待验证] 位宽: 如果 IP 输出 16-bit 左对齐，改为 [15:0]
wire [11:0] adc_data_i0_w, adc_data_q0_w;   // RX1 I/Q
wire [11:0] adc_data_i1_w, adc_data_q1_w;   // RX2 I/Q
wire        adc_valid_0_w, adc_valid_1_w;
wire        adc_clk_w;  // [待验证] 频率: 8/100/200 MHz?

// Step 2: system_wrapper 实例化时新增连接
// (原有端口保持不变，只追加 ADC tap 端口)
system_wrapper i_system_wrapper (
    // ... 原有端口 ...
    // [新增] ADC tap 端口 (需要 Make External 后 wrapper 才有)
    .adc_data_i0    (adc_data_i0_w),   // [待验证] 端口名
    .adc_data_q0    (adc_data_q0_w),
    .adc_data_i1    (adc_data_i1_w),
    .adc_data_q1    (adc_data_q1_w),
    .adc_valid_0    (adc_valid_0_w),
    .adc_valid_1    (adc_valid_1_w),
    .adc_clk_out    (adc_clk_w)
);

// ─────────────────────────────────────────────────────────────
// Step 3: 跨时钟域处理
// adc_clk_w 可能是高速时钟（如 100 MHz），emeye_clk 是 8 MHz (spi_clk)
// 用 axis_clock_converter 或简单的 2-FF synchronizer
// 推荐: 用 Vivado IP axis_clock_converter，避免手写异步 FIFO
//
// 注意: 如果 adc_clk_w 实际就是 8 MHz，可以直接连，不需要 clock converter
// 这必须在 [待验证] 阶段确认
// ─────────────────────────────────────────────────────────────

// 简化写法（假设 adc_clk 就是 emeye 期望的采样率时钟）:
// 如果时钟不同，下面的直连会产生时序违例，Vivado 会报错
wire [11:0] emeye_i0, emeye_q0, emeye_i1, emeye_q1;
wire        emeye_valid_0, emeye_valid_1;

// [待验证] 如果 IP 输出 16-bit 左对齐，改为 adc_data_i0_w[15:4]
assign emeye_i0      = adc_data_i0_w;
assign emeye_q0      = adc_data_q0_w;
assign emeye_i1      = adc_data_i1_w;
assign emeye_q1      = adc_data_q1_w;
assign emeye_valid_0 = adc_valid_0_w;
assign emeye_valid_1 = adc_valid_1_w;

// Step 4: emeye_accel_top 实例化（替换原有 test counter 版本）
emeye_accel_top u_emeye_accel (
    .clk            (adc_clk_w),          // [待验证] 用 adc_clk 还是 spi_clk?
    .rst_n          (gpio_o[16]),
    .cfg_threshold  (12'd50),
    .rx1_i          ($signed(emeye_i0)),   // tap 真实 ADC I0
    .rx1_q          ($signed(emeye_q0)),   // tap 真实 ADC Q0
    .rx1_valid      (emeye_valid_0),
    .rx2_i          ($signed(emeye_i1)),   // tap 真实 ADC I1 (RX2)
    .rx2_q          ($signed(emeye_q1)),
    .rx2_valid      (emeye_valid_1),
    .m_axis_tdata   (emeye_tdata),
    .m_axis_tvalid  (emeye_tvalid),
    .m_axis_tready  (axis_fifo_tready),   // 反压来自 PS 端 FIFO
    .m_axis_tlast   (emeye_tlast)
);
```

---

### 方案 B：更干净 — 在 BD 内部新增 emeye_accel IP Block

**核心思路**: 将 `emeye_accel_top` 打包成 Vivado IP（通过 IP Packager），在 design_1.bd 内部直接连接 axi_ad9361 的 ADC stream 输出到 emeye_accel IP 的输入。

**优点**:
- BD 内部连线清晰，整体设计封装性好
- clock crossing 可以在 BD 里用 axis_clock_converter IP 可视化连接
- IP 复用性高，未来换工程只需 IP Catalog 导入

**缺点**:
- 需要修改 `emeye_accel_top` 接口，把并行 I/Q 输入改成 AXI-Stream slave（tvalid/tready/tdata 打包 I/Q）
- IP Packager 流程有一定学习成本，约需 0.5 天
- 打包后每次 RTL 修改都要重新 packager → re-generate IP → re-synthesize
- 修改 emeye_accel_top 接口意味着 4 个现有 testbench 的端口调用也要同步更新

**方案 B 所需的接口修改（概念）**:

```verilog
// 修改后的 emeye_accel_top AXI-Stream slave 接口 (方案 B 用)
// s_axis: ADC IQ 输入 (从 axi_ad9361 ADC Stream master)
// 打包格式: tdata[63:0] = {q1[15:0], i1[15:0], q0[15:0], i0[15:0]} (待定)
module emeye_accel_top_axis (
    input  wire        aclk,
    input  wire        aresetn,
    // S_AXIS: ADC 输入
    input  wire [63:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // M_AXIS: 幅度帧输出 (不变)
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast,
    // 配置
    input  wire [11:0] cfg_threshold
);
    // 内部从 tdata 拆包 I/Q
    wire signed [11:0] rx1_i = s_axis_tdata[11:0];
    wire signed [11:0] rx1_q = s_axis_tdata[27:16];
    wire signed [11:0] rx2_i = s_axis_tdata[43:32];
    wire signed [11:0] rx2_q = s_axis_tdata[59:48];
    wire rx1_valid = s_axis_tvalid;
    wire rx2_valid = s_axis_tvalid;
    // ... 原有 emeye_accel 逻辑不变 ...
endmodule
```

**推荐选择**: **Phase 2 先走方案 A**，原因如下：
1. 无需改动 emeye_accel_top RTL，4 个已 PASS 的 testbench 不受影响
2. 快速验证 ADC tap 信号是否正确（示波器等效：在 ILA 里抓 emeye_tdata）
3. 方案 B 的 IP packager 工作留到 Phase 3（产品化阶段）再做

---

## 5. emeye_accel_top → PS 数据路径

### 5.1 需要在 BD 里新增的 IP

```
axi_ad9361 ADC Stream
      │ (adc_clk 域, 8 MSPS)
      │ (tap 到 ad9361_top.v 层)
      │
emeye_accel_top (运行在 adc_clk 域)
      │ m_axis (tdata 32-bit, tvalid, tlast)
      │
axis_clock_converter         ← 需要加: adc_clk → FCLK_CLK0 (100 MHz)
      │ (FCLK_CLK0 域)
      │
axis_data_fifo               ← 需要加: depth=1024, 32-bit wide
      │                         作为弹性缓冲，防止 DMA burst 间歇导致丢帧
      │
axi_dma (S2MM 模式)          ← 需要加: PG021 AXI-DMA IP
      │                         S2MM: Stream → DDR
      │ AXI4 HP 口
      │
Zynq PS HP0 (AXI HP0)       ← 已有，接到 DDR
      │
DDR3                         ← 数据落地
      │
PS Linux 用户态              ← TCP forwarder (见 phase2_tcp_forwarder.md)
```

### 5.2 BD 里的具体 IP 连接（Tcl 脚本骨架）

以下 Tcl 仅作概念参考，**不保证在未确认端口名的情况下可以直接执行**：

```tcl
# 打开 BD
open_bd_design [get_files design_1.bd]

# 1. 加 axis_clock_converter（跨域: emeye 输出 adc_clk → FCLK_CLK0）
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clk_conv_0
set_property CONFIG.TDATA_NUM_BYTES {4} [get_bd_cells axis_clk_conv_0]
# 连接时钟
connect_bd_net [get_bd_pins axis_clk_conv_0/s_axis_aclk] \
               [get_bd_pins <adc_clk_source>]         ;# [待验证] adc_clk 来源
connect_bd_net [get_bd_pins axis_clk_conv_0/m_axis_aclk] \
               [get_bd_pins processing_system7_0/FCLK_CLK0]
# 连 aresetn（需要 proc_sys_reset 对应时钟域的 peripheral_aresetn）
connect_bd_net [get_bd_pins axis_clk_conv_0/s_axis_aresetn] \
               [get_bd_pins rst_adc_clk/peripheral_aresetn]   ;# [待验证]
connect_bd_net [get_bd_pins axis_clk_conv_0/m_axis_aresetn] \
               [get_bd_pins rst_ps7_100m/peripheral_aresetn]

# 2. 加 axis_data_fifo（深度 1024，32-bit）
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_fifo_0
set_property CONFIG.FIFO_DEPTH {1024}   [get_bd_cells axis_fifo_0]
set_property CONFIG.TDATA_NUM_BYTES {4} [get_bd_cells axis_fifo_0]
connect_bd_intf_net [get_bd_intf_pins axis_clk_conv_0/M_AXIS] \
                    [get_bd_intf_pins axis_fifo_0/S_AXIS]
connect_bd_net [get_bd_pins axis_fifo_0/s_axis_aclk] \
               [get_bd_pins processing_system7_0/FCLK_CLK0]

# 3. 加 axi_dma（仅 S2MM，关闭 MM2S 节省资源）
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
set_property CONFIG.c_include_sg {0}       [get_bd_cells axi_dma_0]  ;# 关闭 SG
set_property CONFIG.c_include_mm2s {0}     [get_bd_cells axi_dma_0]  ;# 只要 S2MM
set_property CONFIG.c_s2mm_burst_size {256} [get_bd_cells axi_dma_0]
# 连 S_AXIS_S2MM
connect_bd_intf_net [get_bd_intf_pins axis_fifo_0/M_AXIS] \
                    [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]
# 连 AXI-Lite 控制口到 GP0
# 连 M_AXI_S2MM 到 HP0
# [待验证] 具体 AXI Interconnect 连法取决于 BD 里已有的 interconnect 结构

# 4. 分配地址
assign_bd_address
validate_bd_design
save_bd_design
```

### 5.3 中断连接

`axi_dma_0` 的 `s2mm_introut` 需要连到 Zynq PS 的 `IRQ_F2P`，PS Linux 的驱动才能收到 DMA 完成中断。

```tcl
# 连 DMA 中断到 PS IRQ_F2P
connect_bd_net [get_bd_pins axi_dma_0/s2mm_introut] \
               [get_bd_pins processing_system7_0/IRQ_F2P]
```

---

## 6. 时钟域分析与对齐策略

### 6.1 时钟矩阵

| 信号域 | 时钟 | 频率 | 来源 |
|--------|------|------|------|
| AD9361 LVDS 解串 | DATA_CLK | 4~61 MHz (视采样率) | AD9363 PHY |
| axi_ad9361 ADC 输出 | adc_clk | `[待验证]` | BD 内 axi_ad9361 |
| emeye_accel 当前 | spi_clk | ~1-10 MHz | ad9361_top.v |
| AXI Interconnect | FCLK_CLK0 | 100 MHz | PS7 PLL |
| AXI DMA / FIFO | FCLK_CLK0 | 100 MHz | PS7 PLL |

### 6.2 时钟域策略（推荐）

**推荐方案**: 让 emeye_accel_top 跑在 `adc_clk` 上，然后在 emeye 输出侧加 `axis_clock_converter` 跨到 FCLK_CLK0。

```
adc_clk 域:  [axi_ad9361] → tap → [emeye_accel_top] → m_axis
                                                              ↓
FCLK_CLK0域:                                [axis_clock_converter] → [axis_fifo] → [axi_dma] → DDR
```

理由：
- emeye_accel 内部 CIC 和 magnitude 逻辑的采样率参数（`DECIMATE_RATE`）是相对于输入时钟设计的，只要 adc_clk 的实际频率与设计假设的 8 MSPS 对应，内部逻辑不需要改
- 如果 adc_clk 实际是 100 MHz（axi_ad9361 对 8 MSPS 上采样后的接口时钟），那么 CIC 的 DECIMATE_RATE 需要从 `INPUT_RATE/OUTPUT_RATE` 重新计算（100 MHz / 8 MSPS = 12.5，非整数，需要查 IP 的实际时钟结构）

**`[待验证]` 关键动作**: 在 BD 里接 ILA 到 `adc_data_i0` 和 `adc_valid_0`，在 Vivado Hardware Manager 里抓波形，测量两个 valid 上升沿之间的周期数，换算实际采样率。

---

## 7. 约束文件修改

如果 `adc_clk` 是新的时钟域（不在现有 `timing_constraints.xdc` 里），需要新增：

```tcl
# timing_constraints.xdc 新增 (频率数值待测)
# [待验证] adc_clk 端口名以 BD 生成的为准
create_clock -name adc_clk -period 125.000 [get_ports adc_clk_out]  ;# 8 MHz = 125ns

# axis_clock_converter 两侧是异步时钟，声明为 false_path 或 set_clock_groups
set_clock_groups -asynchronous \
    -group [get_clocks adc_clk] \
    -group [get_clocks clk_fpga_0]   ;# FCLK_CLK0
```

---

## 8. Phase 2 第一周工作拆解

### Day 1-2: Sanity Check（必须先做）

- [ ] 打开 `LDSDR_2TR` 工程，打开 `design_1.bd`
- [ ] 确认 `axi_ad9361` IP 版本（ADI HDL 库的哪个 commit）
- [ ] 记录 ADC stream 输出端口完整名称（截图保存）
- [ ] 确认 ADC 数据位宽（12 还是 16 位，左对齐还是右对齐）
- [ ] 确认 adc_clk 连到哪里，频率是多少
- [ ] 查看 LDSDR 原理图，确认 RX2 是否实际引出

### Day 3-4: 方案 A 实施

- [ ] 在 BD 里将 ADC 相关端口 Make External
- [ ] 重新 Generate HDL Wrapper
- [ ] 修改 `ad9361_top.v`：去掉 test_counter，接入真实 ADC wire
- [ ] 在 BD 里加 `axis_clock_converter` + `axis_data_fifo` + `axi_dma`
- [ ] 分配地址空间（axi_dma 的 AXI-Lite 控制口和 HP0 内存范围）
- [ ] 综合运行，检查时序报告（TNS 为 0）

### Day 5: 验证

- [ ] 上板，在 PS 端写小测试程序，启动 S2MM DMA，读 DDR buffer
- [ ] 验证数据不全为零（说明 ADC 在工作）
- [ ] 用 ILA 在 FPGA 上抓 `emeye_tvalid` 和 `emeye_tdata`，确认有变化
- [ ] 与 `simulation/network_demo.py` 协议对接（32-bit 打包格式）

---

## 9. 风险与未知（诚实列表）

| 风险 | 严重程度 | 缓解措施 |
|------|---------|---------|
| axi_ad9361 ADC 端口名与本文假设不符 | 高 | Day 1 必须查 BD，所有端口名需实测确认 |
| adc_clk 实际频率不是 8 MHz，导致 CIC 抽取比失配 | 高 | 加 ILA 抓 valid 周期，可能需要修改 DECIMATE_RATE 参数 |
| LDSDR 硬件 RX2 未引出，rx2_i/q 全零 | 中 | 查原理图；如果只有 RX1 有效，emeye rx2 路置零即可 |
| axis_clock_converter 在 z010 资源不够（LUT/BRAM 紧张） | 中 | 检查综合报告；备选方案是单纯 2-FF synchronizer（仅适合低频信号） |
| axi_dma 需要 Linux 设备树 dma 驱动支持 | 中 | 需要修改 system.dtsi 加 axi_dma 节点；TCP forwarder 里有对应处理 |
| BD 重新生成后 Make External 的端口丢失 | 低 | 建议维护 Tcl 脚本，每次可重复执行 |
| emeye_accel 接收真实 RF 噪声时幅度阈值 50 太低/高 | 低 | 通过 AXI-Lite 寄存器或 GPIO 做运行时可调（Phase 3 任务） |

---

## 10. 参考资料

- ADI HDL 库 axi_ad9361：https://github.com/analogdevicesinc/hdl/tree/main/library/axi_ad9361
- ADI Wiki axi_ad9361：https://wiki.analog.com/resources/fpga/docs/axi_ad9361
- AD9361 Reference Manual (UG-570)：https://www.analog.com/media/en/technical-documentation/user-guides/AD9361_Reference_Manual_UG-570.pdf
- Xilinx AXI-DMA PG021：https://www.xilinx.com/support/documents/ip_documentation/axi_dma/v7_1/pg021_axi_dma.pdf
- Xilinx AXI-Stream FIFO PG080：https://www.xilinx.com/support/documents/ip_documentation/axis_data_fifo/v2_0/pg080-axi-stream-fifo.pdf
- Xilinx AXI-Stream Clock Converter PG061：https://www.xilinx.com/support/documents/ip_documentation/axis_clock_converter/v1_1/pg061-axi4-stream-infrastructure.pdf
- emeye_accel RTL：`../rtl/emeye_accel_top.v`（本项目）
- EM Eye 论文：Hayashi et al. "EM Eye: Characterizing Electromagnetic Side-Channel Eavesdropping on Embedded Cameras" NDSS 2020
