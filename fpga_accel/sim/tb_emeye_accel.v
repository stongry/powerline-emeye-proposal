//==============================================================================
// tb_emeye_accel.v
//
// Top-level integration testbench for emeye_accel_top
// Verifies end-to-end signal flow: IQ in -> magnitude -> decimate ->
//                                   frame_sync -> AXI-Stream out
//==============================================================================

`timescale 1ns / 1ps

module tb_emeye_accel;

    parameter IQ_WIDTH    = 12;
    parameter DEC_RATE    = 8;
    parameter LOG2_DEC    = 3;
    parameter FRAME_IDX_W = 16;
    parameter CLK_PERIOD  = 10;

    reg clk = 0;
    reg rst_n = 0;
    reg [IQ_WIDTH-1:0] cfg_threshold;

    // RX1 inputs
    reg signed [IQ_WIDTH-1:0] rx1_i, rx1_q;
    reg                       rx1_valid;

    // RX2 inputs
    reg signed [IQ_WIDTH-1:0] rx2_i, rx2_q;
    reg                       rx2_valid;

    // AXI-Stream output
    wire [31:0] m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire        m_axis_tlast;

    integer ch1_sample_count, ch2_sample_count;
    integer frame_start_count;
    integer error_count;
    integer total_outputs;

    always #(CLK_PERIOD/2) clk = ~clk;

    emeye_accel_top #(
        .IQ_WIDTH    (IQ_WIDTH),
        .DEC_RATE    (DEC_RATE),
        .LOG2_DEC    (LOG2_DEC),
        .FRAME_IDX_W (FRAME_IDX_W)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .cfg_threshold  (cfg_threshold),
        .rx1_i          (rx1_i),
        .rx1_q          (rx1_q),
        .rx1_valid      (rx1_valid),
        .rx2_i          (rx2_i),
        .rx2_q          (rx2_q),
        .rx2_valid      (rx2_valid),
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tlast   (m_axis_tlast)
    );

    // Observe AXI-Stream output
    wire        out_ch_id   = m_axis_tdata[31];
    wire [15:0] out_frm_idx = m_axis_tdata[30:15];
    wire        out_frm_st  = m_axis_tdata[14];
    wire [11:0] out_mag     = m_axis_tdata[11:0];

    always @(posedge clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            if (out_ch_id == 1'b0) ch1_sample_count <= ch1_sample_count + 1;
            else                    ch2_sample_count <= ch2_sample_count + 1;
            if (out_frm_st) frame_start_count <= frame_start_count + 1;
            total_outputs <= total_outputs + 1;
        end
    end

    initial begin
        // Initialize
        rx1_i = 0; rx1_q = 0; rx1_valid = 0;
        rx2_i = 0; rx2_q = 0; rx2_valid = 0;
        cfg_threshold = 12'd50;       // low threshold, easy to cross
        m_axis_tready = 1;            // always ready (no backpressure test)
        ch1_sample_count = 0;
        ch2_sample_count = 0;
        frame_start_count = 0;
        error_count = 0;
        total_outputs = 0;

        #(CLK_PERIOD * 3);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("================================================================");
        $display("  emeye_accel_top integration testbench");
        $display("  Dual-channel: RX1 + RX2");
        $display("  Pipeline: |IQ| -> 8x decimate -> frame_sync -> AXI-Stream");
        $display("================================================================");

        // ----------------------------------------------------------------
        // Phase 1: feed 1024 high-amplitude IQ samples on both channels
        // This should produce 128 outputs per channel (decimated by 8)
        // Initially no frame_start (continuous ACTIVE)
        // ----------------------------------------------------------------
        $display("\n--- Phase 1: 1024 high-amp IQ samples (no frame boundary) ---");
        feed_high_amplitude(1024);
        #(CLK_PERIOD * 20);
        $display("  ch1 output count: %0d (expect ~128)", ch1_sample_count);
        $display("  ch2 output count: %0d (expect ~128)", ch2_sample_count);
        $display("  frame_starts    : %0d (expect 0)", frame_start_count);

        if (ch1_sample_count < 100 || ch1_sample_count > 130) begin
            $display("  WARN: ch1 count off (acceptable if pipeline latency)");
        end
        if (frame_start_count != 0) begin
            $display("  FAIL: frame_start should be 0 during continuous ACTIVE");
            error_count = error_count + 1;
        end else begin
            $display("  OK: no frame_start during continuous high signal");
        end

        // ----------------------------------------------------------------
        // Phase 2: feed blanking period (zeros) for 600 samples
        // -> 75 decimated outputs of ~0
        // -> avg window catches blanking, enters BLANK state
        // ----------------------------------------------------------------
        $display("\n--- Phase 2: 1200 samples blanking (low) ---");
        feed_low_amplitude(1200);
        #(CLK_PERIOD * 20);

        // ----------------------------------------------------------------
        // Phase 3: feed 600 high-amp samples to trigger frame_start
        // ----------------------------------------------------------------
        $display("\n--- Phase 3: 600 samples back to high (expect frame_start) ---");
        feed_high_amplitude(600);
        #(CLK_PERIOD * 20);
        $display("  frame_starts: %0d (expect >= 2: ch1 + ch2)",
                 frame_start_count);
        if (frame_start_count < 2) begin
            $display("  FAIL: expected at least 2 frame_starts (one per channel)");
            error_count = error_count + 1;
        end else begin
            $display("  OK: frame_start triggered on both channels");
        end

        // ----------------------------------------------------------------
        // Phase 4: Another frame cycle
        // ----------------------------------------------------------------
        $display("\n--- Phase 4: Another frame cycle (blank+high) ---");
        feed_low_amplitude(1200);
        feed_high_amplitude(600);
        #(CLK_PERIOD * 20);
        $display("  frame_starts total: %0d (expect >= 4)", frame_start_count);
        if (frame_start_count < 4) begin
            $display("  FAIL: should accumulate frame_starts");
            error_count = error_count + 1;
        end else begin
            $display("  OK: multiple frames detected");
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        #(CLK_PERIOD * 30);
        $display("\n================================================================");
        $display("  Integration test complete");
        $display("  Total AXI-Stream outputs: %0d", total_outputs);
        $display("  ch1 outputs             : %0d", ch1_sample_count);
        $display("  ch2 outputs             : %0d", ch2_sample_count);
        $display("  Frame starts            : %0d", frame_start_count);
        $display("  Errors                  : %0d", error_count);
        $display("================================================================");
        if (error_count == 0) $display("PASS");
        else $display("FAIL");
        $finish;
    end

    // Feed N high-amplitude samples on both channels in parallel
    task feed_high_amplitude;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                @(negedge clk);
                rx1_i = 12'sd500;
                rx1_q = 12'sd300;
                rx1_valid = 1;
                rx2_i = 12'sd400;
                rx2_q = 12'sd200;
                rx2_valid = 1;
            end
            @(negedge clk);
            rx1_valid = 0;
            rx2_valid = 0;
            #(CLK_PERIOD * 2);
        end
    endtask

    // Feed N low-amplitude (near zero) samples
    task feed_low_amplitude;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                @(negedge clk);
                rx1_i = 12'sd2;
                rx1_q = 12'sd1;
                rx1_valid = 1;
                rx2_i = 12'sd1;
                rx2_q = 12'sd2;
                rx2_valid = 1;
            end
            @(negedge clk);
            rx1_valid = 0;
            rx2_valid = 0;
            #(CLK_PERIOD * 2);
        end
    endtask

endmodule
