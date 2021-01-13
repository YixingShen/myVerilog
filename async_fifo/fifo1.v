`timescale 1 ns / 1 ps
`default_nettype none
//`define D #1 //delay 1 unit
`define D //no delay

module fifo1
    #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
    )(
    output wire [DSIZE-1:0] rd_data,
    output wire wr_full,
    output wire rd_empty,
    input wire [DSIZE-1:0] wr_data,
    input wire wr_en, wr_clk, wr_rst_n,
    input wire rd_en, rd_clk, rd_rst_n
    );

    wire [ASIZE-1:0] wr_addr, rd_addr;
    wire [ASIZE:0] wr_grayptr, rd_grayptr, wq2_rd_ptr, rq2_wr_ptr;

    sync_r2w sync_r2w (.wq2_rd_ptr(wq2_rd_ptr), .rd_grayptr(rd_grayptr),
    .wr_clk(wr_clk), .wr_rst_n(wr_rst_n));

    sync_w2r sync_w2r (.rq2_wr_ptr(rq2_wr_ptr), .wr_grayptr(wr_grayptr),
    .rd_clk(rd_clk), .rd_rst_n(rd_rst_n));

    fifomem #(DSIZE, ASIZE) fifomem
    (.rd_data(rd_data), .wr_data(wr_data),
    .wr_addr(wr_addr), .rd_addr(rd_addr),
    .wr_en(wr_en), .wr_full(wr_full), .wr_clk(wr_clk),
    .rd_en(rd_en), .rd_empty(rd_empty), .rd_clk(rd_clk));

    rd_ptr_empty #(ASIZE) rd_ptr_empty
    (.rd_empty(rd_empty),
    .rd_addr(rd_addr),
    .rd_grayptr(rd_grayptr), .rq2_wr_ptr(rq2_wr_ptr),
    .rd_en(rd_en), .rd_clk(rd_clk),
    .rd_rst_n(rd_rst_n));

    wr_ptr_full #(ASIZE) wr_ptr_full
    (.wr_full(wr_full), .wr_addr(wr_addr),
    .wr_grayptr(wr_grayptr), .wq2_rd_ptr(wq2_rd_ptr),
    .wr_en(wr_en), .wr_clk(wr_clk),
    .wr_rst_n(wr_rst_n));

endmodule

`resetall
