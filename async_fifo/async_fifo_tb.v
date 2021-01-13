`timescale 1 ns / 1 ps
`default_nettype none

`include "fifo1.v"
`include "fifomem.v"
`include "sync_r2w.v"
`include "sync_w2r.v"
`include "wptr_full.v"
`include "rptr_empty.v"

module async_fifo_tb;
    parameter DSIZE = 8;
    parameter ASIZE = 3;

    wire [DSIZE-1:0] rd_data;
    wire wr_full;
    wire rd_empty;
    reg [DSIZE-1:0] wr_data;
    reg wr_en, wr_clk, wr_rst_n;
    reg rd_en, rd_clk, rd_rst_n;
    reg clk;
    
    fifo1 #(DSIZE, ASIZE) fifo_inst (.rd_data(rd_data), .wr_full(wr_full),
                                     .rd_empty(rd_empty), .wr_data(wr_data),
                                     .wr_en(wr_en), .wr_clk(wr_clk), .wr_rst_n(wr_rst_n),
                                     .rd_en(rd_en), .rd_clk(rd_clk), .rd_rst_n(rd_rst_n));

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0,async_fifo_tb);
        $dumpvars();

        rd_rst_n = 0;
        wr_rst_n = 0;
        rd_clk = 0;
        wr_clk = 0;
        clk = 0;
        wr_en = 0;
        rd_en = 0;
        
        #20;
        rd_rst_n = 1;
        #20;
        wr_rst_n = 1;
        #20;
        wr_en = 1;
        rd_en = 1;
        #20;
    end

    initial begin
        $monitor("%x %x", rd_data, wr_data);
        #1000;
        $dumpflush;
        $finish;
    end

    task writeData;
        input reg [DSIZE-1:0] x;
        begin
        #2 wr_clk = 0;
        wr_data = x;
        wr_en = 1;
        #2 wr_clk = 1;
        end
    endtask
    
    task readData;
        begin
        #2 rd_clk = 0;
        rd_en = 1;
        #2 rd_clk = 1;
        end
    endtask

    always @(negedge rd_clk) begin
        if (rd_rst_n == 0) begin
        end
        else if (!rd_empty) begin
            rd_en = 1;
        end
        else begin
            rd_en = 0;
        end
    end
    
    always @(negedge wr_clk) begin
        if (wr_rst_n == 0) begin
        end
        else if (!wr_full) begin
            wr_en = 1;
            wr_data = ($random) % 256;
        end
        else begin
            wr_en = 0;
            wr_data = 0;
        end
    end
    
    always begin 
        #1 clk = ~clk;
    end
    
    always begin
        @(posedge clk)
        @(posedge clk)
        rd_clk = 0;
        @(posedge clk)
        @(posedge clk)
        rd_clk = 1;
    end
    
    always begin
        @(negedge clk)
        @(negedge clk)
        @(negedge clk)
        wr_clk = 0;
        @(negedge clk)
        @(negedge clk)
        @(negedge clk)
        wr_clk = 1;
    end

endmodule

`resetall
