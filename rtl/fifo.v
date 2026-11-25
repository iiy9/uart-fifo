// Synchronous FIFO, one clock. rd_data is valid one cycle after an accepted read.
module fifo #(parameter WIDTH = 8, parameter AW = 4) (
  input  wire             clk, rst,
  input  wire             wr_en,
  input  wire [WIDTH-1:0] wr_data,
  input  wire             rd_en,
  output reg  [WIDTH-1:0] rd_data,
  output wire             full, empty
);
  reg [WIDTH-1:0] mem [0:(1<<AW)-1];
  // One extra pointer bit tells "full" from "empty" when the addresses match.
  reg [AW:0] wp, rp;

  assign empty = (wp == rp);
  assign full  = (wp[AW] != rp[AW]) && (wp[AW-1:0] == rp[AW-1:0]);

  always @(posedge clk) begin
    if (rst) begin
      wp <= 0; rp <= 0; rd_data <= 0;
    end else begin
      if (wr_en && !full) begin
        mem[wp[AW-1:0]] <= wr_data;
        wp <= wp + 1'b1;
      end
      if (rd_en && !empty) begin
        rd_data <= mem[rp[AW-1:0]];
        rp <= rp + 1'b1;
      end
    end
  end
endmodule
