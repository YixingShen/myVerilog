/* reference referencedesigner.com */

`timescale 1ns / 100ps

module top;
reg Clock;
reg D;
wire Q;
reg Rst;
integer i;

dff uut (
.Clock(Clock),
.D(D),
.Rst(Rst),
.Q(Q)
);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,top);

	#3  D = 1'bz; Rst = 1'bz;
	#3  D = 0;    Rst = 0;
	#3  D = 1;    Rst = 1;
	#10 D = 0;
	#10 D = 0;
	#10 D = 1;
    #10 D = 0;
	#10 D = 1;
	#10 D = 1;
	#10 D = 1;
	#5  Rst = 0;
	#10 D = 1;
	#5  Rst = 0;
	#5  Rst = 1;
	#10 D = 1;
	#10 D = 0;
	#10 D = 1;
	#10 D = 0;
	#40;

    $dumpflush;
end //initial begin

initial begin
    Clock = 0;

    for (i = 0; i <= 20; i = i+1) begin
       #10 Clock = ~Clock;
    end
end  
    
initial begin
$monitor("time = %2d, Clock = %d, D = %d, Rst = %d, Q = %d",$time,Clock,D,Rst,Q);
end

endmodule