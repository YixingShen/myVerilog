`timescale 1 ns / 1 ps
`default_nettype none
//`define D #1 //delay 1 unit
`define D //no delay

module wr_ptr_full
    #(
    parameter ADDRSIZE = 4
    )(
    output reg wr_full,
    output wire [ADDRSIZE-1:0] wr_addr,
    output reg [ADDRSIZE :0] wr_grayptr,
    input wire [ADDRSIZE :0] wq2_rd_ptr,
    input wire wr_en, wr_clk, wr_rst_n
    );

    reg [ADDRSIZE:0] wr_ptr;
    wire [ADDRSIZE:0] wr_grayptr_next, wr_ptr_next;
    wire wr_full_val;

    // GRAYSTYLE2 pointer
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            {wr_ptr, wr_grayptr} <= `D 0;
        else
            {wr_ptr, wr_grayptr} <= `D {wr_ptr_next, wr_grayptr_next};
    end

    // Memory write-address pointer (okay to use binary to address memory)
    assign wr_addr = wr_ptr[ADDRSIZE-1:0];
    assign wr_ptr_next = wr_ptr + (wr_en & ~wr_full);
    assign wr_grayptr_next = (wr_ptr_next>>1) ^ wr_ptr_next;

    //------------------------------------------------------------------
    // Simplified version of the three necessary full-tests:
    // assign wr_full_val = ( (wr_grayptr_next[ADDRSIZE] != wq2_rd_ptr[ADDRSIZE]) &&
    // (wr_grayptr_next[ADDRSIZE-1] != wq2_rd_ptr[ADDRSIZE-1]) &&
    // (wr_grayptr_next[ADDRSIZE-2:0] == wq2_rd_ptr[ADDRSIZE-2:0]) );
    //------------------------------------------------------------------
    assign wr_full_val = (wr_grayptr_next == {~wq2_rd_ptr[ADDRSIZE:ADDRSIZE-1],wq2_rd_ptr[ADDRSIZE-2:0]});
    //wq2_rd_ptr pointer to reading word 

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            wr_full <= `D 1'b0;
        else
            wr_full <= `D wr_full_val;
    end

endmodule

`resetall
