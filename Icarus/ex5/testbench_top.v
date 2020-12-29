/* reference referencedesigner.com */

`timescale 1ns / 1ps
module top;
    reg [4:1] x;
    wire [2:0] pcode;

    priory_encoder_case uut (
        .x(x),
        .pcode(pcode)
    );

    initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,top);

    x = 4'bzzzz;

    #20;

    for (x = 0; x < 15; x++) begin
        #20;
    end //for (x = 0; x < 15; x++) begin

    #20;

    $dumpflush;
    end //initial begin

    initial begin
    $monitor("t = %3d, x = %4b, pcode = %3b", $time, x, pcode);
    end //initial begin

endmodule
