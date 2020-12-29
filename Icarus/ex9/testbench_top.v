/* reference referencedesigner.com */

`timescale 1ns / 100ps

module top;
reg Clock;
reg Reset;
reg S_IN;
wire S_OUT;
integer i;

shift_reg #(.N(10)) uut (
.Clock(Clock),
.Reset(Reset),
.S_IN(S_IN),
.S_OUT(S_OUT)
);

//shift_reg uut (
//.Clock(Clock),
//.Reset(Reset),
//.S_IN(S_IN),
//.S_OUT(S_OUT)
//);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,top);
    $printtimescale;
    
    Reset = 1;
    S_IN = 0;

	#2 S_IN = 0; Reset = 0;
	#2 Reset = 1;
    
    for (i = 0; i <= 10; i = i + 1) begin
	    #20 S_IN = ~S_IN;
    end
    #20 S_IN = 1;
    #20 S_IN = 1;
    #20 S_IN = 0;
    #20 S_IN = 1;
    //#20 S_IN = 0;
    //#20 S_IN = 1;
    //#20 S_IN = 1;
    //#20 S_IN = 1;
    //#20 S_IN = 0;
	#40;

    $dumpflush;
end //initial begin

initial begin
    Clock = 0;

    for (i = 0; i <= 60; i = i+1) begin
       #10 Clock = ~Clock;
    end
end  
    
initial begin
$monitor("time = %2d, Clock = %d, Reset = %d, S_IN = %d, S_OUT = %d",$time,Clock,Reset,S_IN,S_OUT);
end

endmodule