// UART receiver, 8N1. Samples each bit in the middle.
module uart_rx #(parameter CLKS_PER_BIT = 16) (
  input  wire       clk, rst,
  input  wire       rx,
  output reg  [7:0] data,
  output reg        valid,      // one-cycle pulse, good frame
  output reg        frame_err   // one-cycle pulse, stop bit was 0
);
  localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

  reg [1:0]  sync;              // rx comes from another clock domain
  reg [1:0]  state;
  reg [15:0] cnt;
  reg [2:0]  idx;
  reg [7:0]  sh;
  wire       rxs = sync[1];

  always @(posedge clk) begin
    sync <= {sync[0], rx};
    valid <= 1'b0;
    frame_err <= 1'b0;
    if (rst) begin
      sync <= 2'b11; state <= IDLE; cnt <= 0; idx <= 0; data <= 0; sh <= 0;
    end else case (state)
      IDLE: begin
        cnt <= 0;
        if (!rxs) state <= START;
      end
      START: if (cnt == CLKS_PER_BIT/2 - 1) begin
        cnt   <= 0;
        idx   <= 0;
        state <= rxs ? IDLE : DATA;   // a short glitch is not a start bit
      end else cnt <= cnt + 1'b1;
      DATA: if (cnt == CLKS_PER_BIT-1) begin
        cnt <= 0;
        sh  <= {rxs, sh[7:1]};
        idx <= idx + 1'b1;
        if (idx == 3'd7) state <= STOP;
      end else cnt <= cnt + 1'b1;
      STOP: if (cnt == CLKS_PER_BIT-1) begin
        cnt   <= 0;
        state <= IDLE;
        if (rxs) begin data <= sh; valid <= 1'b1; end
        else frame_err <= 1'b1;
      end else cnt <= cnt + 1'b1;
    endcase
  end
endmodule
