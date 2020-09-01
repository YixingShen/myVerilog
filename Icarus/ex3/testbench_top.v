/* Written by referencedesigner.com */

`timescale 1ns / 100ps

module top; 

reg input1;
reg input2;
reg carryin;

wire out;
wire carryout;

fulladder uut (
    .x(input1),
    .y(input2),
    .cin(carryin),
    .A(out),
    .cout(carryout)
);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,top);
    input1 = 0;
    input2 = 0;
    carryin = 0;

    #20; input1 = 0; input2 = 0;
    #20; input1 = 0; input2 = 1;
    #20; input1 = 1; input2 = 0;
    #20; input1 = 1; input2 = 1;
    #20; carryin = 1;
    #20; input1 = 0; input2 = 0;
    #20; input1 = 0; input2 = 1;
    #20; input1 = 1; input2 = 0;
    #20; input1 = 1; input2 = 1;
    #40;

    //#20; input1 = 1;
    //#20; input2 = 1;
    //#20; input1 = 0;
    //#20; carryin = 1;
    //#20; input2 = 0;
    //#20; input1 = 1;
    //#20; input2 = 1;
    //#40;
end

initial begin
$monitor("time = %2d, \tCIN = %1b, \tIN1 = %1b, \tIN2 = %1b, \tCOUT = %1b, \tOUT = %1b",$time,carryin,input2,input1,carryout,out);
end

endmodule
