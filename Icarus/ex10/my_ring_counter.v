/* reference referencedesigner.com */

`timescale 1ns / 100ps

module ring_counter #(parameter N = 4) (Clock, Reset, q);
input wire Clock, Reset;
output wire[N-1:0] q;

reg[N-1:0] next;

assign q = next;

always @(posedge Clock, negedge Reset) begin
    $display("N = %2d", N);

    if (!Reset) begin
        next <= {{(N-1){1'b0}}, {1'b1}};
    end else begin
        next <= next << 1;
        next[0] <= next[N-1];
    end
    //$display("time = %2d, \$display: r_reg=%b", $stime, r_reg);
end

endmodule
