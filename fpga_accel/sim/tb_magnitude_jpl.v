//==============================================================================
// tb_magnitude_jpl.v
//
// Testbench for magnitude_jpl module
// Verifies JPL approximation against floating-point reference
//==============================================================================

`timescale 1ns / 1ps

module tb_magnitude_jpl;

    parameter IN_WIDTH = 12;
    parameter OUT_WIDTH = 12;
    parameter CLK_PERIOD = 10;  // 100 MHz simulation clock

    reg clk = 0;
    reg rst_n = 0;
    reg signed [IN_WIDTH-1:0] i_in;
    reg signed [IN_WIDTH-1:0] q_in;
    reg valid_in;

    wire [OUT_WIDTH-1:0] mag_out;
    wire valid_out;

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // DUT
    magnitude_jpl #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_in(i_in),
        .q_in(q_in),
        .valid_in(valid_in),
        .mag_out(mag_out),
        .valid_out(valid_out)
    );

    // Test vectors
    integer test_idx;
    integer error_count;
    real expected, error_pct;
    real abs_i_real, abs_q_real, max_real, min_real, jpl_real;

    // Reference: software JPL approximation (for cross-check)
    function automatic real jpl_ref(input real i_val, input real q_val);
        real abs_i, abs_q, mx, mn;
        begin
            abs_i = (i_val < 0) ? -i_val : i_val;
            abs_q = (q_val < 0) ? -q_val : q_val;
            mx = (abs_i > abs_q) ? abs_i : abs_q;
            mn = (abs_i > abs_q) ? abs_q : abs_i;
            jpl_ref = mx + 0.375 * mn;
        end
    endfunction

    // Reference: exact magnitude (for accuracy assessment)
    function automatic real exact_mag(input real i_val, input real q_val);
        begin
            exact_mag = $sqrt(i_val*i_val + q_val*q_val);
        end
    endfunction

    initial begin
        // Initialize
        i_in = 0;
        q_in = 0;
        valid_in = 0;
        test_idx = 0;
        error_count = 0;

        // Reset
        #(CLK_PERIOD * 3);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("================================================================");
        $display("  magnitude_jpl testbench");
        $display("  Format: idx | I, Q | JPL_hw | JPL_sw | Exact | err_vs_exact %%");
        $display("================================================================");

        // Test vector set 1: known cases
        run_test(0, 0);             // mag = 0
        run_test(2047, 0);          // mag = 2047 (pure I)
        run_test(0, 2047);          // mag = 2047 (pure Q)
        run_test(2047, 2047);       // mag = sqrt(2) * 2047 ≈ 2895
        run_test(-2048, 0);         // negative I
        run_test(0, -2048);         // negative Q
        run_test(-1000, -1000);     // both negative
        run_test(1000, -1000);      // mixed sign
        run_test(500, 1500);        // arbitrary
        run_test(100, 50);          // small values

        // Random test set
        $display("\n--- Random test (50 vectors) ---");
        for (test_idx = 0; test_idx < 50; test_idx = test_idx + 1) begin
            run_test($random % 2048, $random % 2048);
        end

        // Summary
        #(CLK_PERIOD * 10);
        $display("\n================================================================");
        $display("  Test complete");
        $display("  Errors (|JPL_hw - JPL_sw| > 1 LSB): %0d", error_count);
        $display("================================================================");

        if (error_count == 0)
            $display("PASS");
        else
            $display("FAIL");

        $finish;
    end

    // Apply test vector and check output
    task run_test;
        input signed [IN_WIDTH-1:0] ti;
        input signed [IN_WIDTH-1:0] tq;
        real jpl_sw, exact_val, hw_val;
        integer err_lsb;
        begin
            @(negedge clk);
            i_in = ti;
            q_in = tq;
            valid_in = 1;
            @(negedge clk);
            valid_in = 0;

            // Wait for pipeline (3 cycles)
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);

            hw_val = mag_out;
            jpl_sw = jpl_ref(ti, tq);
            exact_val = exact_mag(ti, tq);
            err_lsb = (hw_val > jpl_sw) ? (hw_val - jpl_sw) : (jpl_sw - hw_val);
            if (err_lsb > 1) error_count = error_count + 1;

            if (exact_val > 0)
                error_pct = 100.0 * (jpl_sw - exact_val) / exact_val;
            else
                error_pct = 0;

            $display("  [%3d] I=%5d Q=%5d | HW=%5d SW=%5.0f Exact=%5.1f | err=%6.2f%%",
                     test_idx, ti, tq, hw_val, jpl_sw, exact_val, error_pct);
        end
    endtask

endmodule
