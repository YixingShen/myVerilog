module edge_wait_example();

reg enable, clk, trigger;

always @ (posedge enable)
begin 
  trigger = 0;
  // Wait for 5 clock cycles
  repeat (5) begin
    @ (posedge clk) ;
  end
  trigger = 1; 
end

//Testbench code here
initial begin
  $dumpfile("wave.vcd");
  $dumpvars(0,edge_wait_example);
  $printtimescale;

  $monitor ("TIME : %g CLK : %b ENABLE : %b TRIGGER : %b",
    $time, clk,enable,trigger);
  clk = 0;
  enable = 0;
  trigger = 1;

  #1 enable = 1;
  #1 enable = 0;
  #1 enable = 1;
  #1 enable = 0;

  //#5  enable = 1;
  #10  enable = 1;

  #1  enable = 0;
  #10 enable = 1;
  #1  enable = 0;
  #10 $finish;
end

always
 #1 clk = ~clk;

endmodule