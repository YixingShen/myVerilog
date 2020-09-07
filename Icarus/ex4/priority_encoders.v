/* Written by referencedesigner.com */

`timescale 1ns / 100ps

module priory_encoder_casez(A, pcode);

input wire [4:1] A;
output reg [2:0] pcode;

always @(*) begin
    casez (A)
        4'b1zzz:
        begin
            $display("casez 4'b1zzz");
            pcode = 3'b100;
        end
        4'b01zz:
        begin
            $display("casez 4'b01zz");
            pcode = 3'b011;
        end
        4'b001z:
        begin
            $display("casez 4'b001z");
            pcode = 3'b010;
        end
        4'b0001:
        begin
            $display("casez 4'b0001");
            pcode = 3'b001;
        end
        4'b0000:
        begin
            $display("casez 4'b0000");
            pcode = 3'b000;
        end
        default:
        begin
            $display("casez default");
            pcode = 3'b111;
        end
    endcase
end

endmodule
