/* reference referencedesigner.com */

`timescale 1ns / 100ps

module shift_reg #(parameter N = 4) (Clock, Reset, S_IN, S_OUT);
input wire Clock, Reset;
input wire S_IN;
output wire S_OUT;

reg [N-1:0] r_reg;
wire [N-1:0] r_next;

assign r_next = {S_IN, r_reg[N-1:1]};
assign S_OUT = r_reg[0];

always @(posedge Clock, negedge Reset) begin
    if (!Reset) begin
        r_reg <= #1 0;
    end else begin
        r_reg <= r_next;
    end
    $display("time = %2d, \$display: r_reg=%b", $stime, r_reg);
end

endmodule
