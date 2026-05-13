//==============================================================================
// tb_frame_sync.v
//
// Testbench for frame_sync module
// Verifies blanking-based frame boundary detection
//==============================================================================

`timescale 1ns / 1ps

module tb_frame_sync;

    parameter DATA_WIDTH  = 12;
    parameter FRAME_IDX_W = 16;
    parameter CLK_PERIOD  = 10;

    reg clk = 0;
    reg rst_n = 0;
    reg [DATA_WIDTH-1:0] threshold;
    reg [DATA_WIDTH-1:0] data_in;
    reg valid_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire [FRAME_IDX_W-1:0] frame_idx;
    wire frame_start;
    wire valid_out;

    integer frame_start_count;
    integer expected_frames;
    integer error_count;

    always #(CLK_PERIOD/2) clk = ~clk;

    frame_sync #(
        .DATA_WIDTH (DATA_WIDTH),
        .FRAME_IDX_W(FRAME_IDX_W)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .threshold  (threshold),
        .data_in    (data_in),
        .valid_in   (valid_in),
        .data_out   (data_out),
        .frame_idx  (frame_idx),
        .frame_start(frame_start),
        .valid_out  (valid_out)
    );

    // Count frame_start pulses
    always @(posedge clk) begin
        if (frame_start) frame_start_count <= frame_start_count + 1;
    end

    initial begin
        data_in = 0;
        valid_in = 0;
        threshold = 12'd100;
        frame_start_count = 0;
        error_count = 0;

        #(CLK_PERIOD * 3);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("================================================================");
        $display("  frame_sync testbench (blanking detection FSM)");
        $display("  threshold = %0d", threshold);
        $display("================================================================");

        // ----------------------------------------------------------------
        // Test 1: Constant high signal -> stay ACTIVE, no frame_start
        // ----------------------------------------------------------------
        $display("\n--- Test 1: 200 samples ACTIVE (val=500) ---");
        feed_value(12'd500, 200);
        $display("  frame_start_count after high signal: %0d (expect 0)",
                 frame_start_count);
        if (frame_start_count != 0) begin
            $display("  FAIL: should not assert frame_start during ACTIVE");
            error_count = error_count + 1;
        end else begin
            $display("  OK: no frame_start during continuous ACTIVE");
        end

        // ----------------------------------------------------------------
        // Test 2: Frame boundary - drop signal, then back up
        // ----------------------------------------------------------------
        $display("\n--- Test 2: 100 samples BLANK (val=0) then 100 ACTIVE (val=500) ---");
        $display("  Expect frame_start_count to increment by 1");
        expected_frames = frame_start_count + 1;
        feed_value(12'd0, 100);    // blanking
        feed_value(12'd500, 100);  // active again -> trigger frame_start
        $display("  frame_start_count: %0d (expect %0d)",
                 frame_start_count, expected_frames);
        if (frame_start_count != expected_frames) begin
            $display("  FAIL");
            error_count = error_count + 1;
        end else begin
            $display("  OK: frame_start asserted on BLANK->ACTIVE transition");
        end

        // ----------------------------------------------------------------
        // Test 3: Multiple frame cycles
        // ----------------------------------------------------------------
        $display("\n--- Test 3: 3 more frame cycles ---");
        expected_frames = frame_start_count + 3;
        repeat (3) begin
            feed_value(12'd0, 100);
            feed_value(12'd500, 100);
        end
        $display("  frame_start_count: %0d (expect %0d)",
                 frame_start_count, expected_frames);
        if (frame_start_count != expected_frames) begin
            $display("  FAIL");
            error_count = error_count + 1;
        end else begin
            $display("  OK: 3 frames correctly detected");
        end

        // ----------------------------------------------------------------
        // Test 4: Frame index increments correctly
        // ----------------------------------------------------------------
        $display("\n--- Test 4: Verify frame_idx increments ---");
        $display("  Current frame_idx = %0d", frame_idx);
        if (frame_idx != frame_start_count) begin
            $display("  FAIL: frame_idx (%0d) != frame_start_count (%0d)",
                     frame_idx, frame_start_count);
            error_count = error_count + 1;
        end else begin
            $display("  OK: frame_idx matches frame_start_count");
        end

        // ----------------------------------------------------------------
        // Test 5: Short blanking (< BLANK_MIN=64) should NOT trigger
        // ----------------------------------------------------------------
        $display("\n--- Test 5: Short blanking (40 samples) should NOT trigger ---");
        expected_frames = frame_start_count;
        feed_value(12'd0, 40);     // not enough for BLANK confirmation
        feed_value(12'd500, 100);  // back to active
        $display("  frame_start_count: %0d (expect %0d, no change)",
                 frame_start_count, expected_frames);
        if (frame_start_count != expected_frames) begin
            $display("  FAIL: short blanking should not trigger frame boundary");
            error_count = error_count + 1;
        end else begin
            $display("  OK: short blanking correctly ignored");
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        #(CLK_PERIOD * 10);
        $display("\n================================================================");
        $display("  Test complete");
        $display("  Frame starts detected: %0d", frame_start_count);
        $display("  Errors               : %0d", error_count);
        $display("================================================================");
        if (error_count == 0) $display("PASS");
        else $display("FAIL");
        $finish;
    end

    task feed_value;
        input [DATA_WIDTH-1:0] val;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                @(negedge clk);
                data_in = val;
                valid_in = 1;
            end
            @(negedge clk);
            valid_in = 0;
            #(CLK_PERIOD * 2);
        end
    endtask

endmodule
