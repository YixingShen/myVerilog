/* reference referencedesigner.com */

`timescale 1ns / 100ps

module dff (Clock, D, Q);
input wire Clock;
input wire D;
output reg Q;

always @(posedge Clock) begin
    Q = D;
end

endmodule
