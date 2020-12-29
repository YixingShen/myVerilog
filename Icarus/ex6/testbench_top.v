/* reference referencedesigner.com */

`timescale 1ns / 100ps

module top;
parameter width = 8;

reg [width-1:0] input1;
reg [width-1:0] input2;
reg carryin;

wire [width-1:0] out;
wire carryout;

fulladder #(.N(width)) uut (
.in1(input1),
.in2(input2),
.cin(carryin),
.sum(out),
.cout(carryout)
);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,top);
    input1 = 0;
    input2 = 0;
    carryin = 0;
    #20 input1 = 1;
    #20 input2 = 2;
    #20 input1 = 0;
    #20 carryin = 1;
    #20 input2 = 0;
    #20 input1 = 15; 
    #20 input2 = 15;
    #40;
    $dumpflush;
end //initial begin

initial begin
$monitor("time = %2d, CIN =%1b, IN1=%X, IN2=%X, COUT=%1b, OUT=%X", $time,carryin,input2,input1,carryout,out);
end

endmodule