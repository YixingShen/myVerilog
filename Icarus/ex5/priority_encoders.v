/* reference referencedesigner.com */

`timescale 1ns / 100ps

module priory_encoder_case(x, pcode);

input wire [4:1] x;
output reg [2:0] pcode;

always @(*) begin
    case (x)
        4'b1000, 4'b1001, 4'b1010, 4'b1011, 4'b1100, 4'b1101, 4'b1110, 4'b1111:
        begin
            pcode = 3'b100;
        end
        4'b0100, 4'b0101, 4'b0110, 4'b0111:
        begin
            pcode = 3'b011;
        end
        4'b0010, 4'b0011:
        begin
            pcode = 3'b010;
        end
        4'b0001:
        begin
            pcode = 3'b001;
        end
        4'b0000: 
        begin
            pcode = 3'b000;
        end
    endcase
end

endmodule
