/* reference referencedesigner.com */

`timescale 1ns / 100ps
//`define SyncronousReset

module dff (Clock, D, Q, Rst);
input wire Clock;
input wire D;
input wire Rst;
output reg Q;

`ifdef SyncronousReset
always @(posedge Clock) begin
    if (!Rst) begin
        Q = 0;
    end
    else begin
        Q = D;
    end
end
`else
always @(posedge Clock or negedge Rst) begin
    if (Rst == 0) begin
        Q = 0;
    end
    else begin
        Q = D;
    end
end
`endif

endmodule
