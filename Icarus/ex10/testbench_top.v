/* reference referencedesigner.com */

`timescale 1ns / 100ps

module top;
reg Clock;
reg Reset;
parameter tbN = 8;
wire[tbN-1:0] q;
integer i;
//defparam uut.N = 6;

ring_counter #(.N(tbN)) uut (
.Clock(Clock),
.Reset(Reset),
.q(q)
);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,top);
    $printtimescale;
    
    Reset = 1;

	#2 Reset = 0;
	#2 Reset = 1;

    $dumpflush;
end //initial begin

initial begin
    Clock = 0;

    for (i = 0; i <= 60; i = i+1) begin
       #10 Clock = ~Clock;
    end
end  
    
initial begin
$monitor("time = %2d, Clock = %d, Reset = %d, q = %4b",$time,Clock,Reset,q);
end

endmodule