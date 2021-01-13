`timescale 1 ns / 1 ps
`default_nettype none
//`define D #1 //delay 1 unit
`define D //no delay

module sync_w2r //sync wr_grayptr to rd_clk domain
    #(
    parameter ADDRSIZE = 4
    )(
    output reg [ADDRSIZE:0] rq2_wr_ptr,
    input wire [ADDRSIZE:0] wr_grayptr,
    input wire rd_clk,
    input wire rd_rst_n
    );

    reg [ADDRSIZE:0] rq1_wr_ptr;
    
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            {rq2_wr_ptr,rq1_wr_ptr} <= `D 0;
        else
            {rq2_wr_ptr,rq1_wr_ptr} <= `D {rq1_wr_ptr,wr_grayptr};
    end

endmodule

`resetall
