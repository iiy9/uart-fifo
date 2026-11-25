`timescale 1ns/1ps
module tb_fifo;
  reg clk = 0, rst = 1, wr_en = 0, rd_en = 0; reg [7:0] wr_data = 0;
  wire [7:0] rd_data; wire full, empty;
  fifo dut(.clk(clk), .rst(rst), .wr_en(wr_en), .wr_data(wr_data), .rd_en(rd_en),
           .rd_data(rd_data), .full(full), .empty(empty));
  always #5 clk = ~clk;

  reg [7:0] q [0:65535]; integer head = 0, tail = 0, errors = 0, i, seed = 7;
  reg [7:0] exp; reg chk; integer fulls = 0, empties = 0;

  // Drive on negedge so the DUT sees stable inputs at posedge.
  task step(input w, input r, input [7:0] d);
    begin
      wr_en = w; rd_en = r; wr_data = d; chk = 0;
      if (full !== (tail-head == 16)) begin errors = errors+1; $display("FAIL full at %0t", $time); end
      if (empty !== (tail == head))   begin errors = errors+1; $display("FAIL empty at %0t", $time); end
      if (full) fulls = fulls+1;
      if (empty) empties = empties+1;
      if (r && tail != head) begin exp = q[head]; chk = 1; end
      if (w && (tail-head) < 16) begin q[tail] = d; tail = tail+1; end
      if (chk) head = head+1;
      @(negedge clk);
      if (chk && rd_data !== exp) begin errors = errors+1; $display("FAIL data %h exp %h", rd_data, exp); end
    end
  endtask

  initial begin
    @(negedge clk); @(negedge clk); rst = 0;
    step(0,1,0);                                        // read while empty
    for (i=0;i<20;i=i+1) step(1,0,i);                   // overfill
    for (i=0;i<20;i=i+1) step(0,1,0);                   // overdrain
    for (i=0;i<8;i=i+1)  step(1,0,8'hA0+i);
    for (i=0;i<40;i=i+1) step(1,1,i);                   // simultaneous, wraps
    for (i=0;i<4000;i=i+1) step($random(seed), $random(seed), $random(seed));
    for (i=0;i<200;i=i+1) step(1,(i%4)==0,i);           // mostly writes
    if (fulls == 0 || empties == 0) begin errors = errors+1; $display("FAIL corner not reached"); end
    if (errors == 0) $display("PASS fifo");
    $finish;
  end
endmodule
