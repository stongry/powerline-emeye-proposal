//==============================================================================
// emeye_accel_top.v
//
// EM Eye Power-Line Side-Channel Project - Phase 2 FPGA Acceleration
//
// Top-level module integrating:
//   1. Dual-channel magnitude calculation (|I+jQ|) for RX1 + RX2
//      (LDSDR has 2T2R, both RX channels can capture in parallel)
//   2. Decimation (8x by default, reduces 8 MSPS → 1 MSPS)
//   3. Frame boundary detection
//   4. AXI-Stream output to PS via DMA
//
// Bandwidth reduction:
//   Input  : 2 ch × 8 MSPS × 12-bit × 2(I+Q) = 384 Mbps
//   Output : 2 ch × 1 MSPS × 12-bit         =  24 Mbps
//   Compression ratio: 16x
//
// Target: Xilinx Zynq XC7Z010 (LDSDR PL fabric)
//   Resource estimate (per channel):
//     - magnitude_jpl:   ~80 LUTs, 0 DSP, 0 BRAM
//     - cic_decimator:   ~50 LUTs, 0 DSP, 0 BRAM
//     - frame_sync:     ~120 LUTs, 0 DSP, 0 BRAM
//     - AXI-Stream FIFO: ~100 LUTs, 0 DSP, 1 BRAM
//   Total (2 ch + glue): ~600 LUTs (3% of XC7Z010's 17.6k LUTs)
//                         1 BRAM   (3% of XC7Z010's 60 BRAMs)
//                         0 DSP    (0% of XC7Z010's 80 DSPs)
//   Leaves abundant resources for future expansion (multi-band fusion etc.)
//==============================================================================

`timescale 1ns / 1ps

module emeye_accel_top #(
    parameter IQ_WIDTH     = 12,
    parameter DEC_RATE     = 8,
    parameter LOG2_DEC     = 3,
    parameter FRAME_IDX_W  = 16
) (
    input  wire                       clk,           // AD9363 sample clock (~8 MHz)
    input  wire                       rst_n,

    // Runtime configuration (from PS via AXI-Lite, simplified here)
    input  wire [IQ_WIDTH-1:0]        cfg_threshold,  // blanking threshold

    // ----------------------- Input: AD9363 IQ streams -----------------------
    // Channel 1 (RX1)
    input  wire signed [IQ_WIDTH-1:0] rx1_i,
    input  wire signed [IQ_WIDTH-1:0] rx1_q,
    input  wire                       rx1_valid,

    // Channel 2 (RX2) -- for multi-band fusion (EM Eye Eq. 3)
    input  wire signed [IQ_WIDTH-1:0] rx2_i,
    input  wire signed [IQ_WIDTH-1:0] rx2_q,
    input  wire                       rx2_valid,

    // ----------------------- Output: AXI-Stream to PS -----------------------
    // Packed format: {ch_id[0], frame_idx[15:0], frame_start, mag[11:0]} = 30 bits
    // Sized to 32-bit for AXI-Stream tdata width
    output reg  [31:0]                m_axis_tdata,
    output reg                        m_axis_tvalid,
    input  wire                       m_axis_tready,
    output reg                        m_axis_tlast    // last sample of frame
);

    // ============================================================
    // Channel 1 datapath
    // ============================================================
    wire [IQ_WIDTH-1:0] ch1_mag;
    wire                ch1_mag_valid;

    magnitude_jpl #(
        .IN_WIDTH(IQ_WIDTH),
        .OUT_WIDTH(IQ_WIDTH)
    ) u_mag_ch1 (
        .clk      (clk),
        .rst_n    (rst_n),
        .i_in     (rx1_i),
        .q_in     (rx1_q),
        .valid_in (rx1_valid),
        .mag_out  (ch1_mag),
        .valid_out(ch1_mag_valid)
    );

    wire [IQ_WIDTH-1:0] ch1_dec;
    wire                ch1_dec_valid;

    cic_decimator #(
        .IN_WIDTH (IQ_WIDTH),
        .OUT_WIDTH(IQ_WIDTH),
        .DEC_RATE (DEC_RATE),
        .LOG2_DEC (LOG2_DEC)
    ) u_dec_ch1 (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (ch1_mag),
        .valid_in (ch1_mag_valid),
        .data_out (ch1_dec),
        .valid_out(ch1_dec_valid)
    );

    wire [IQ_WIDTH-1:0]      ch1_sync_mag;
    wire [FRAME_IDX_W-1:0]   ch1_frame_idx;
    wire                     ch1_frame_start;
    wire                     ch1_sync_valid;

    frame_sync #(
        .DATA_WIDTH (IQ_WIDTH),
        .FRAME_IDX_W(FRAME_IDX_W)
    ) u_sync_ch1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .threshold  (cfg_threshold),
        .data_in    (ch1_dec),
        .valid_in   (ch1_dec_valid),
        .data_out   (ch1_sync_mag),
        .frame_idx  (ch1_frame_idx),
        .frame_start(ch1_frame_start),
        .valid_out  (ch1_sync_valid)
    );

    // ============================================================
    // Channel 2 datapath (mirror of channel 1)
    // ============================================================
    wire [IQ_WIDTH-1:0]    ch2_mag;
    wire                   ch2_mag_valid;

    magnitude_jpl #(
        .IN_WIDTH(IQ_WIDTH),
        .OUT_WIDTH(IQ_WIDTH)
    ) u_mag_ch2 (
        .clk      (clk),
        .rst_n    (rst_n),
        .i_in     (rx2_i),
        .q_in     (rx2_q),
        .valid_in (rx2_valid),
        .mag_out  (ch2_mag),
        .valid_out(ch2_mag_valid)
    );

    wire [IQ_WIDTH-1:0] ch2_dec;
    wire                ch2_dec_valid;

    cic_decimator #(
        .IN_WIDTH (IQ_WIDTH),
        .OUT_WIDTH(IQ_WIDTH),
        .DEC_RATE (DEC_RATE),
        .LOG2_DEC (LOG2_DEC)
    ) u_dec_ch2 (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (ch2_mag),
        .valid_in (ch2_mag_valid),
        .data_out (ch2_dec),
        .valid_out(ch2_dec_valid)
    );

    wire [IQ_WIDTH-1:0]    ch2_sync_mag;
    wire [FRAME_IDX_W-1:0] ch2_frame_idx;
    wire                   ch2_frame_start;
    wire                   ch2_sync_valid;

    frame_sync #(
        .DATA_WIDTH (IQ_WIDTH),
        .FRAME_IDX_W(FRAME_IDX_W)
    ) u_sync_ch2 (
        .clk        (clk),
        .rst_n      (rst_n),
        .threshold  (cfg_threshold),
        .data_in    (ch2_dec),
        .valid_in   (ch2_dec_valid),
        .data_out   (ch2_sync_mag),
        .frame_idx  (ch2_frame_idx),
        .frame_start(ch2_frame_start),
        .valid_out  (ch2_sync_valid)
    );

    // ============================================================
    // Round-robin AXI-Stream output with 1-deep pending buffer
    // per channel (avoids losing samples when both channels arrive
    // simultaneously)
    // ============================================================
    reg [IQ_WIDTH-1:0]     ch1_pend_mag, ch2_pend_mag;
    reg [FRAME_IDX_W-1:0]  ch1_pend_idx, ch2_pend_idx;
    reg                    ch1_pend_start, ch2_pend_start;
    reg                    ch1_pending, ch2_pending;
    reg                    ch_select;  // 0 = next is ch1, 1 = next is ch2

    always @(posedge clk) begin
        if (!rst_n) begin
            ch1_pending    <= 1'b0;
            ch2_pending    <= 1'b0;
            ch1_pend_mag   <= {IQ_WIDTH{1'b0}};
            ch2_pend_mag   <= {IQ_WIDTH{1'b0}};
            ch1_pend_idx   <= {FRAME_IDX_W{1'b0}};
            ch2_pend_idx   <= {FRAME_IDX_W{1'b0}};
            ch1_pend_start <= 1'b0;
            ch2_pend_start <= 1'b0;
            ch_select      <= 1'b0;
            m_axis_tdata   <= 32'b0;
            m_axis_tvalid  <= 1'b0;
            m_axis_tlast   <= 1'b0;
        end else begin
            // ----------------------------------------------------
            // Capture from frame_sync outputs into pending buffer
            // ----------------------------------------------------
            if (ch1_sync_valid && !ch1_pending) begin
                ch1_pend_mag   <= ch1_sync_mag;
                ch1_pend_idx   <= ch1_frame_idx;
                ch1_pend_start <= ch1_frame_start;
                ch1_pending    <= 1'b1;
            end
            if (ch2_sync_valid && !ch2_pending) begin
                ch2_pend_mag   <= ch2_sync_mag;
                ch2_pend_idx   <= ch2_frame_idx;
                ch2_pend_start <= ch2_frame_start;
                ch2_pending    <= 1'b1;
            end

            // ----------------------------------------------------
            // AXI-Stream output (round-robin with fallback)
            // ----------------------------------------------------
            if (m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;

                if (ch_select == 1'b0 && ch1_pending) begin
                    // Send ch1 sample
                    m_axis_tdata  <= {1'b0, ch1_pend_idx,
                                      ch1_pend_start, 2'b0, ch1_pend_mag};
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast  <= ch1_pend_start;
                    ch1_pending   <= 1'b0;
                    ch_select     <= 1'b1;
                end else if (ch_select == 1'b1 && ch2_pending) begin
                    // Send ch2 sample
                    m_axis_tdata  <= {1'b1, ch2_pend_idx,
                                      ch2_pend_start, 2'b0, ch2_pend_mag};
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast  <= ch2_pend_start;
                    ch2_pending   <= 1'b0;
                    ch_select     <= 1'b0;
                end else if (ch1_pending) begin
                    // Fallback: send ch1 if ch2 not ready
                    m_axis_tdata  <= {1'b0, ch1_pend_idx,
                                      ch1_pend_start, 2'b0, ch1_pend_mag};
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast  <= ch1_pend_start;
                    ch1_pending   <= 1'b0;
                end else if (ch2_pending) begin
                    // Fallback: send ch2 if ch1 not ready
                    m_axis_tdata  <= {1'b1, ch2_pend_idx,
                                      ch2_pend_start, 2'b0, ch2_pend_mag};
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast  <= ch2_pend_start;
                    ch2_pending   <= 1'b0;
                end
            end
        end
    end

endmodule

//==============================================================================
// Integration with LDSDR Vivado project (existing OFDM+LDPC workflow):
//
//  1. Add these RTL files to existing project src/hdl/ directory
//  2. In block design (BD), instantiate emeye_accel_top between
//     AD9363 (axi_ad9361_v6_0) and PS-PL bus (axi_dma_0)
//  3. Connect AD9363 RX1/RX2 to rx1_*/rx2_* inputs
//  4. Connect m_axis_* to axi_dma_0 S_AXIS_S2MM
//  5. Add AXI-Lite slave (not shown here) for cfg_threshold programming
//  6. Run synthesis: target XC7Z010 -2 speed grade
//  7. Verify timing closure at AD9363 clock (typically 30.72 MHz max)
//
// Expected timing closure: WNS > +2 ns at 30.72 MHz
// (this is a low-frequency design relative to Zynq-7010 capability ~500 MHz)
//
// Verification flow:
//  1. tb_magnitude_jpl.v - unit test for magnitude module
//  2. tb_emeye_accel.v   - integrated testbench with simulated IQ
//  3. Bit-true Python model (see emeye_accel_bitmodel.py) for golden output
//  4. Hardware-in-the-loop: feed test pattern through Pluto/LDSDR loopback
//==============================================================================
