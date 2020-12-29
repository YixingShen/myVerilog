/* reference referencedesigner.com */

`timescale 1ns / 100ps

`define ANSI_Style

`ifdef ANSI_Style
module fulladder #(parameter N = 8) (in1, in2, cin, sum, cout);
`else
module fulladder (in1, in2, cin, sum, cout);
parameter N = 8;
`endif

input wire [N-1:0] in1, in2;
input wire cin;
output wire [N-1:0] sum;
output wire cout;

wire [N:0] tempsum;

assign tempsum = {1'b0, in1} + {1'b0, in2} + cin;
assign sum = tempsum[N-1:0];
assign cout = tempsum[N];

endmodule
