/* reference referencedesigner.com */

`timescale 1ns / 100ps

module top;
reg Clock;
reg D;
wire Q;
integer i;

dff uut (
.Clock(Clock),
.D(D),
.Q(Q)
);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,top);

    D = 0;
    #8  D = 1;
    #10 D = 0;
    #10 D = 0;
    #10 D = 1;
    #10 D = 0;
    #10 D = 1;
    #40;

    $dumpflush;
end //initial begin

initial begin
    Clock = 0;

    for (i = 0; i <= 10; i = i+1) begin
       #10 Clock = ~Clock;
    end
end

initial begin
$monitor("time = %2d, Clock = %d, D = %d, Q = %d",$time,Clock,D,Q);
end

endmodule