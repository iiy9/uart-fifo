// UART transmitter, 8N1, least significant bit first.
module uart_tx #(parameter CLKS_PER_BIT = 16) (
  input  wire       clk, rst,
  input  wire       start,
  input  wire [7:0] data,
  output reg        tx,
  output wire       busy
);
  reg [9:0]  shift;    // {stop, data[7:0], start}
  reg [3:0]  bits;     // bits left to send
  reg [15:0] cnt;

  assign busy = (bits != 0);

  always @(posedge clk) begin
    if (rst) begin
      tx <= 1'b1; bits <= 0; cnt <= 0; shift <= 10'h3ff;
    end else if (!busy) begin
      tx <= 1'b1;
      if (start) begin
        shift <= {1'b1, data, 1'b0};
        tx    <= 1'b0;
        bits  <= 4'd10;
        cnt   <= 0;
      end
    end else if (cnt == CLKS_PER_BIT-1) begin
      cnt   <= 0;
      bits  <= bits - 1'b1;
      shift <= {1'b1, shift[9:1]};
      tx    <= shift[1];
    end else
      cnt <= cnt + 1'b1;
  end
endmodule
