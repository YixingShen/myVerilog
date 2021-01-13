`timescale 1 ns / 1 ps
`default_nettype none
//`define D #1 //delay 1 unit
`define D //no delay

module sync_r2w //sync rd_grayptr to wr_clk domain
    #(
    parameter ADDRSIZE = 4
    )(
    output reg [ADDRSIZE:0] wq2_rd_ptr,
    input wire [ADDRSIZE:0] rd_grayptr,
    input wire wr_clk, wr_rst_n
    );

    reg [ADDRSIZE:0] wq1_rd_ptr;

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            {wq2_rd_ptr,wq1_rd_ptr} <= `D 0;
        else
            {wq2_rd_ptr,wq1_rd_ptr} <= `D {wq1_rd_ptr,rd_grayptr};
    end

endmodule

`resetall
