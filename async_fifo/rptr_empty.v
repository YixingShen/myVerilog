`timescale 1 ns / 1 ps
`default_nettype none
//`define D #1 //delay 1 unit
`define D //no delay

module rd_ptr_empty
    #(
    parameter ADDRSIZE = 4
    )(
    output reg rd_empty,
    output wire [ADDRSIZE-1:0] rd_addr,
    output reg [ADDRSIZE :0] rd_grayptr,
    input wire [ADDRSIZE :0] rq2_wr_ptr,
    input wire rd_en, rd_clk, rd_rst_n
    );

    reg [ADDRSIZE:0] rd_ptr;
    wire [ADDRSIZE:0] rd_grayptr_next, rd_ptr_next;
    wire rd_empty_val;

    //-------------------
    // GRAYSTYLE2 pointer
    //-------------------
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            {rd_ptr, rd_grayptr} <= `D 0;
        else
            {rd_ptr, rd_grayptr} <= `D {rd_ptr_next, rd_grayptr_next};
    end

    // Memory read-address pointer (okay to use binary to address memory)
    assign rd_addr = rd_ptr[ADDRSIZE-1:0];
    assign rd_ptr_next = rd_ptr + (rd_en & ~rd_empty);
    assign rd_grayptr_next = (rd_ptr_next>>1) ^ rd_ptr_next;

    //---------------------------------------------------------------
    // FIFO empty when the next rd_ptr == synchronized wptr or on reset
    //---------------------------------------------------------------
    assign rd_empty_val = (rd_grayptr_next == rq2_wr_ptr);
    //rq2_wr_ptr pointer to the next word to written. rd_empty_val = 1 : has been empty or will be empty  

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            rd_empty <= `D 1'b1;
        else
            rd_empty <= `D rd_empty_val;
    end

endmodule

`resetall
