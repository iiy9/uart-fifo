`timescale 1ns/1ps
module tb_uart_tx;
  localparam C = 8;
  reg clk = 0, rst = 1, start = 0; reg [7:0] data = 0; wire tx, busy;
  uart_tx #(.CLKS_PER_BIT(C)) dut(.clk(clk), .rst(rst), .start(start), .data(data), .tx(tx), .busy(busy));
  always #5 clk = ~clk;
  integer errors = 0, b, k, n; reg [9:0] frame;

  task send(input [7:0] d);
    begin
      frame = {1'b1, d, 1'b0};
      data = d; start = 1; @(negedge clk); start = 0; data = ~d;
      for (b=0;b<10;b=b+1) for (k=0;k<C;k=k+1) begin
        if (tx !== frame[b]) begin errors = errors+1; $display("FAIL byte %h bit %0d clk %0d", d, b, k); end
        if (!busy)           begin errors = errors+1; $display("FAIL busy low in frame"); end
        start = (b == 4);                                // must be ignored while busy
        @(negedge clk);
      end
      start = 0;
      if (busy) begin errors = errors+1; $display("FAIL busy stuck"); end
    end
  endtask

  initial begin
    @(negedge clk); @(negedge clk); rst = 0; @(negedge clk);
    if (tx !== 1) begin errors = errors+1; $display("FAIL idle level"); end
    for (n=0;n<256;n=n+1) send(n);                       // back to back
    if (errors == 0) $display("PASS uart_tx");
    $finish;
  end
endmodule
