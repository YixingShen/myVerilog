`timescale 1 ns / 1 ps
`default_nettype none
//`define D #1 //delay 1 unit
`define D //no delay

module fifomem 
    #(
    parameter DATASIZE = 8, // Memory data word width
    parameter ADDRSIZE = 4 // Number of mem address bits
    )(
    output wire [DATASIZE-1:0] rd_data,
    input wire [DATASIZE-1:0] wr_data,
    input wire [ADDRSIZE-1:0] wr_addr, rd_addr,
    input wire wr_en, wr_full, wr_clk,
    input wire rd_en, rd_empty, rd_clk
    );

    // RTL Verilog memory model
    localparam DEPTH = 1<<ADDRSIZE;
    reg [DATASIZE-1:0] mem [0:DEPTH-1];
    //reg [DATASIZE-1:0] wr_data_t;
    //assign rd_data = mem[rd_addr];

    reg [DATASIZE-1:0] rd_data_t;
    reg wr_ack, rd_ack;

    always @(posedge rd_clk) begin
        if (rd_en && !rd_empty) begin
            rd_data_t <= `D mem[rd_addr];
            rd_ack <= 1;
        end
        else begin
            rd_ack <= 0;
            rd_data_t <= `D {DATASIZE{1'bz}};
        end
    end

    assign rd_data = rd_data_t;

    always @(posedge wr_clk) begin
        if (wr_en && !wr_full) begin
            mem[wr_addr] <= `D wr_data;
            wr_ack <= 1;
        end
        else begin
            wr_ack <= 0;
        end
    end
    
endmodule

`resetall
