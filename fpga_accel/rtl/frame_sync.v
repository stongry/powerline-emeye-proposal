//==============================================================================
// frame_sync.v
//
// EM Eye Power-Line Side-Channel Project - Phase 2 FPGA Acceleration
//
// Module: Frame boundary detection by blanking period sensing
//
// Strategy: The amplitude signal drops to near-noise level during the
// blanking interval between frames. Detect a sustained low-amplitude
// region to mark frame boundaries.
//
// Algorithm:
//   1. Compute running average over a small window (~16 samples)
//   2. Compare to a threshold (programmable via THRESHOLD register)
//   3. Frame boundary: low-amplitude region lasting > BLANKING_MIN samples
//   4. Increment frame_idx at each detected boundary
//   5. Pass-through data with frame_idx tag
//
// This is a coarse sync — Tf precision ~ 1 sample at decimated rate.
// Fine sync (sub-sample) is done in host PC post-processing.
//
// Hardware cost: ~120 LUTs, no DSP, no BRAM
//==============================================================================

`timescale 1ns / 1ps

module frame_sync #(
    parameter DATA_WIDTH    = 12,
    parameter FRAME_IDX_W   = 16,    // 16-bit counter = 65535 frames max
    parameter AVG_WINDOW    = 16,    // running avg window
    parameter LOG2_WINDOW   = 4,     // log2(AVG_WINDOW)
    parameter DEFAULT_THRESH = 64    // threshold below this = "blanking"
) (
    input  wire                       clk,
    input  wire                       rst_n,

    // Configuration
    input  wire [DATA_WIDTH-1:0]      threshold,    // blanking detection level

    // Input decimated amplitude stream
    input  wire [DATA_WIDTH-1:0]      data_in,
    input  wire                       valid_in,

    // Output with frame index tag
    output reg  [DATA_WIDTH-1:0]      data_out,
    output reg  [FRAME_IDX_W-1:0]     frame_idx,
    output reg                        frame_start,   // 1-cycle pulse at frame begin
    output reg                        valid_out
);

    // ------------------------------------------------------------
    // Running average over AVG_WINDOW samples
    // ------------------------------------------------------------
    reg [DATA_WIDTH-1:0] window [AVG_WINDOW-1:0];
    reg [DATA_WIDTH+LOG2_WINDOW-1:0] win_sum;
    reg [LOG2_WINDOW-1:0] win_ptr;

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < AVG_WINDOW; i = i + 1) begin
                window[i] <= {DATA_WIDTH{1'b0}};
            end
            win_sum <= {(DATA_WIDTH+LOG2_WINDOW){1'b0}};
            win_ptr <= {LOG2_WINDOW{1'b0}};
        end else if (valid_in) begin
            // Update running sum: subtract oldest, add newest
            win_sum <= win_sum - window[win_ptr] + data_in;
            window[win_ptr] <= data_in;
            win_ptr <= win_ptr + 1'b1;
        end
    end

    wire [DATA_WIDTH-1:0] avg_amp = win_sum >> LOG2_WINDOW;

    // ------------------------------------------------------------
    // Blanking state machine
    // ------------------------------------------------------------
    // STATE_ACTIVE: signal above threshold (data transmission ongoing)
    // STATE_BLANK : signal below threshold (between frames)
    // Transition ACTIVE → BLANK: start of blanking period
    // Transition BLANK → ACTIVE: start of new frame (assert frame_start)

    localparam STATE_ACTIVE = 1'b0;
    localparam STATE_BLANK  = 1'b1;

    reg                  state;
    reg [15:0]           blank_cnt;     // count samples in blanking
    localparam BLANK_MIN = 64;          // min samples to confirm blanking

    always @(posedge clk) begin
        if (!rst_n) begin
            state       <= STATE_ACTIVE;
            blank_cnt   <= 16'd0;
            frame_idx   <= {FRAME_IDX_W{1'b0}};
            frame_start <= 1'b0;
            data_out    <= {DATA_WIDTH{1'b0}};
            valid_out   <= 1'b0;
        end else begin
            frame_start <= 1'b0;
            valid_out   <= 1'b0;

            if (valid_in) begin
                data_out  <= data_in;
                valid_out <= 1'b1;

                case (state)
                    STATE_ACTIVE: begin
                        if (avg_amp < threshold) begin
                            blank_cnt <= blank_cnt + 1'b1;
                            if (blank_cnt >= BLANK_MIN) begin
                                state <= STATE_BLANK;
                            end
                        end else begin
                            blank_cnt <= 16'd0;
                        end
                    end

                    STATE_BLANK: begin
                        if (avg_amp >= threshold) begin
                            // Signal returned: this is start of new frame
                            state       <= STATE_ACTIVE;
                            blank_cnt   <= 16'd0;
                            frame_idx   <= frame_idx + 1'b1;
                            frame_start <= 1'b1;
                        end
                    end
                endcase
            end
        end
    end

endmodule

//==============================================================================
// Verification notes:
// - At 1 MSPS decimated rate, BLANK_MIN=64 means ~64 us blanking detection
// - Real EM Eye blanking is typically 50-200 us, so detection is reliable
// - Threshold needs runtime tuning based on noise floor
// - Frame index wraps at 2^16 = 65535 frames (~2200 seconds at 30 fps,
//   sufficient for any practical Phase 0 capture)
//==============================================================================
