/* Written by referencedesigner.com */

`timescale 1ns / 100ps

module comparator(
	input x,
	input y,
	output z
);
udp_syntax udp (z, x, y);
endmodule

// User Defined Primitive
primitive udp_syntax (out, in1, in2);
	output out;
	input in1,in2;
 
table
// in1  in2  : out
    0    0   : 1; 
    0    1   : 0; 
    1    0   : 0; 
    1    1   : 1; 
endtable
endprimitive