//==============================================================================
// tb_cic_decimator.v
//
// Testbench for cic_decimator module
// Verifies 8x boxcar averaging + decimation
//==============================================================================

`timescale 1ns / 1ps

module tb_cic_decimator;

    parameter IN_WIDTH  = 12;
    parameter OUT_WIDTH = 12;
    parameter DEC_RATE  = 8;
    parameter LOG2_DEC  = 3;
    parameter CLK_PERIOD = 10;

    reg clk = 0;
    reg rst_n = 0;
    reg [IN_WIDTH-1:0] data_in;
    reg valid_in;
    wire [OUT_WIDTH-1:0] data_out;
    wire valid_out;

    integer error_count;
    integer total_outputs;
    integer expected_avg;

    always #(CLK_PERIOD/2) clk = ~clk;

    cic_decimator #(
        .IN_WIDTH (IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .DEC_RATE (DEC_RATE),
        .LOG2_DEC (LOG2_DEC)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_in),
        .valid_in (valid_in),
        .data_out (data_out),
        .valid_out(valid_out)
    );

    // Capture outputs
    reg [OUT_WIDTH-1:0] captured [0:31];
    integer cap_idx;

    always @(posedge clk) begin
        if (valid_out) begin
            captured[cap_idx] <= data_out;
            cap_idx <= cap_idx + 1;
        end
    end

    initial begin
        data_in = 0;
        valid_in = 0;
        error_count = 0;
        total_outputs = 0;
        cap_idx = 0;

        #(CLK_PERIOD * 3);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("================================================================");
        $display("  cic_decimator testbench (8x boxcar decimator)");
        $display("================================================================");

        // ----------------------------------------------------------------
        // Test 1: Constant input = 100 -> output should be 100
        // ----------------------------------------------------------------
        $display("\n--- Test 1: Constant input = 100 ---");
        cap_idx = 0;
        feed_constant(12'd100, 24);  // feed 24 samples (= 3 output samples)
        wait_for_outputs;
        check_outputs(3, 100, "constant 100");

        // ----------------------------------------------------------------
        // Test 2: Constant input = 2047 (max signed positive)
        // ----------------------------------------------------------------
        $display("\n--- Test 2: Constant input = 2047 ---");
        cap_idx = 0;
        feed_constant(12'd2047, 24);
        wait_for_outputs;
        check_outputs(3, 2047, "constant 2047");

        // ----------------------------------------------------------------
        // Test 3: Constant input = 0
        // ----------------------------------------------------------------
        $display("\n--- Test 3: Constant input = 0 ---");
        cap_idx = 0;
        feed_constant(12'd0, 16);
        wait_for_outputs;
        check_outputs(2, 0, "constant 0");

        // ----------------------------------------------------------------
        // Test 4: Ramp 0,1,2,...,7 -> avg should be (0+1+...+7)/8 = 3.5 -> 3
        // ----------------------------------------------------------------
        $display("\n--- Test 4: Ramp 0..7 (8 samples) -> expect avg 3 ---");
        cap_idx = 0;
        feed_ramp(0, 8);
        wait_for_outputs;
        check_outputs(1, 3, "ramp 0..7 avg");

        // ----------------------------------------------------------------
        // Test 5: Ramp 8,9,...,15 -> avg = (8+9+...+15)/8 = 11.5 -> 11
        // ----------------------------------------------------------------
        $display("\n--- Test 5: Ramp 8..15 -> expect avg 11 ---");
        cap_idx = 0;
        feed_ramp(8, 8);
        wait_for_outputs;
        check_outputs(1, 11, "ramp 8..15 avg");

        // ----------------------------------------------------------------
        // Test 6: Alternating 0/200 -> avg should be (0+200)*4/8 = 100
        // ----------------------------------------------------------------
        $display("\n--- Test 6: Alternating 0/200 -> expect 100 ---");
        cap_idx = 0;
        feed_alternating(8);
        wait_for_outputs;
        check_outputs(1, 100, "alt 0/200");

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        #(CLK_PERIOD * 10);
        $display("\n================================================================");
        $display("  Test complete");
        $display("  Total outputs checked: %0d", total_outputs);
        $display("  Errors               : %0d", error_count);
        $display("================================================================");
        if (error_count == 0) $display("PASS");
        else $display("FAIL");
        $finish;
    end

    // Feed N constant samples
    task feed_constant;
        input [IN_WIDTH-1:0] val;
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
        end
    endtask

    // Feed ramp starting at start_val
    task feed_ramp;
        input [IN_WIDTH-1:0] start_val;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                @(negedge clk);
                data_in = start_val + i;
                valid_in = 1;
            end
            @(negedge clk);
            valid_in = 0;
        end
    endtask

    // Feed alternating 0/200
    task feed_alternating;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                @(negedge clk);
                data_in = (i % 2 == 0) ? 12'd0 : 12'd200;
                valid_in = 1;
            end
            @(negedge clk);
            valid_in = 0;
        end
    endtask

    // Wait for pipeline to flush
    task wait_for_outputs;
        begin
            #(CLK_PERIOD * 5);
        end
    endtask

    // Check captured outputs match expected
    task check_outputs;
        input integer expected_count;
        input [OUT_WIDTH-1:0] expected_val;
        input [127:0] test_name;
        integer i;
        integer diff;
        begin
            if (cap_idx != expected_count) begin
                $display("  [%s] Expected %0d outputs, got %0d",
                         test_name, expected_count, cap_idx);
                error_count = error_count + 1;
            end
            for (i = 0; i < cap_idx; i = i + 1) begin
                diff = (captured[i] > expected_val) ? (captured[i] - expected_val)
                                                     : (expected_val - captured[i]);
                if (diff > 1) begin
                    $display("  [%s] Output[%0d]=%0d, expected %0d (diff %0d) FAIL",
                             test_name, i, captured[i], expected_val, diff);
                    error_count = error_count + 1;
                end else begin
                    $display("  [%s] Output[%0d]=%0d (expect %0d, diff %0d) OK",
                             test_name, i, captured[i], expected_val, diff);
                end
                total_outputs = total_outputs + 1;
            end
        end
    endtask

endmodule
