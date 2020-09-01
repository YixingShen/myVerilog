/* Written by referencedesigner.com */

`timescale 1ns / 100ps

module fulladder
(
    input x,
    input y,
    input cin,

    output A, 
    output cout
);

assign {cout,A} = cin + y + x;

endmodule