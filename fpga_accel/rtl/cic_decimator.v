//==============================================================================
// cic_decimator.v
//
// EM Eye Power-Line Side-Channel Project - Phase 2 FPGA Acceleration
//
// Module: Boxcar (moving average) decimator for amplitude stream
//
// Reduces sample rate by DEC_RATE while averaging input samples.
// For DEC_RATE=8: 8 MSPS magnitude → 1 MSPS averaged output
//
// This is a single-stage CIC (technically a boxcar accumulator + dump).
// For our application this is sufficient since:
//   - We're after EM Eye pipeline gain reduction (not communication SDR)
//   - Frequency response of 1st-order sinc filter is adequate
//   - Real bandwidth reduction comes from the 32x rate cut
//
// Hardware cost: ~50 LUTs, no DSP, no BRAM
//
// Target platform: LDSDR (Xilinx Zynq-7010 XC7Z010CLG400)
//==============================================================================

`timescale 1ns / 1ps

module cic_decimator #(
    parameter IN_WIDTH    = 12,
    parameter OUT_WIDTH   = 12,
    parameter DEC_RATE    = 8,
    parameter LOG2_DEC    = 3       // log2(DEC_RATE), must match
) (
    input  wire                  clk,
    input  wire                  rst_n,

    // Input stream (from magnitude_jpl)
    input  wire [IN_WIDTH-1:0]   data_in,
    input  wire                  valid_in,

    // Output decimated stream
    output reg  [OUT_WIDTH-1:0]  data_out,
    output reg                   valid_out
);

    // Accumulator: wider than input to hold sum of DEC_RATE samples
    // For 12-bit input, DEC_RATE=8: accum needs 12+3=15 bits
    localparam ACC_WIDTH = IN_WIDTH + LOG2_DEC;

    reg [ACC_WIDTH-1:0] accum;
    reg [LOG2_DEC-1:0]  cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            accum     <= {ACC_WIDTH{1'b0}};
            cnt       <= {LOG2_DEC{1'b0}};
            data_out  <= {OUT_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;  // default: no output

            if (valid_in) begin
                if (cnt == DEC_RATE - 1) begin
                    // Last sample in this decimation block
                    // Output average = (accum + data_in) >> LOG2_DEC
                    data_out  <= (accum + data_in) >> LOG2_DEC;
                    accum     <= {ACC_WIDTH{1'b0}};
                    cnt       <= {LOG2_DEC{1'b0}};
                    valid_out <= 1'b1;
                end else begin
                    accum <= accum + data_in;
                    cnt   <= cnt + 1'b1;
                end
            end
        end
    end

endmodule

//==============================================================================
// Verification notes:
// - Input rate: 8 MSPS (matching AD9363 fs)
// - Output rate: 8/DEC_RATE MSPS
// - Frequency response: sinc(N·ω/2) / sinc(ω/2), with notches at fs/N
// - For DEC_RATE=8, fs=8MSPS: notches at 1MHz, 2MHz, 3MHz, ... (alias rejection)
// - This is acceptable since the EM Eye signal is narrowband (image content
//   has bandwidth << 1 MHz at typical 200-300 line frame rates)
//
// Future enhancement: replace with multi-stage CIC for better stopband
//==============================================================================
