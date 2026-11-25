`timescale 1ns/1ps
module tb_uart_loop;
  localparam C = 16;
  reg clk = 0, rst = 1, start = 0; reg [7:0] data = 0; wire tx, busy;
  reg force_line = 0, line = 1; wire rx = force_line ? line : tx;
  wire [7:0] rd; wire valid, ferr;
  uart_tx #(.CLKS_PER_BIT(C)) t(.clk(clk), .rst(rst), .start(start), .data(data), .tx(tx), .busy(busy));
  uart_rx #(.CLKS_PER_BIT(C)) r(.clk(clk), .rst(rst), .rx(rx), .data(rd), .valid(valid), .frame_err(ferr));
  always #5 clk = ~clk;
  integer errors = 0, n, i, good = 0, bad = 0; reg [7:0] last;
  always @(negedge clk) begin if (valid) begin good = good+1; last = rd; end if (ferr) bad = bad+1; end

  task frame(input [7:0] d, input stop, input integer bitclks);   // hand-made frame
    begin
      line = 0; repeat (bitclks) @(negedge clk);
      for (i=0;i<8;i=i+1) begin line = d[i]; repeat (bitclks) @(negedge clk); end
      line = stop; repeat (bitclks) @(negedge clk);
      line = 1; repeat (3*C) @(negedge clk);
    end
  endtask

  initial begin
    repeat (4) @(negedge clk); rst = 0; repeat (4) @(negedge clk);
    for (n=0;n<256;n=n+1) begin
      data = n; start = 1; @(negedge clk); start = 0;
      while (busy) @(negedge clk);
      repeat (4) @(negedge clk);
      if (good !== n+1 || last !== n[7:0]) begin errors = errors+1; $display("FAIL byte %0d got %h", n, last); end
    end
    force_line = 1; good = 0; bad = 0;
    line = 0; repeat (3) @(negedge clk); line = 1; repeat (12*C) @(negedge clk);
    if (good != 0 || bad != 0) begin errors = errors+1; $display("FAIL glitch accepted"); end
    frame(8'h55, 0, C);
    if (bad != 1 || good != 0) begin errors = errors+1; $display("FAIL bad stop not flagged"); end
    frame(8'hA7, 1, C);
    if (good != 1 || last !== 8'hA7) begin errors = errors+1; $display("FAIL no recovery"); end
    frame(8'h3C, 1, C-1); frame(8'hC3, 1, C+1);          // about 6 percent baud error in bits 0-8
    $display("note: after baud offset good=%0d bad=%0d (informative)", good, bad);
    if (errors == 0) $display("PASS uart_loop");
    $finish;
  end
endmodule
