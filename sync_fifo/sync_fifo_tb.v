`timescale 1 ns / 1 ps
`default_nettype none

module syn_fifo_tb;
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 3;

    parameter DIR_WR    = 0;
    parameter DIR_RD    = 1;
    parameter DIR_WR_RD = 2;
    parameter DIR_CLOSE = 3;

    reg [DATA_WIDTH-1:0] data_out;
    wire [DATA_WIDTH-1:0] rd_data;
    reg [DATA_WIDTH-1:0] wr_data;
    wire wr_full;
    wire rd_empty;
    reg wr_en, clk, rst_n, rd_en;
    
    sync_fifo #(DATA_WIDTH,ADDR_WIDTH) sync_fifo_inst (.clk(clk),
                                                       .rst_n(rst_n),
                                                       .wr_en(wr_en),
                                                       .wr_full(wr_full),
                                                       .wr_data(wr_data), 
                                                       .rd_en(rd_en),
                                                       .rd_empty(rd_empty),
                                                       .rd_data(rd_data)
                                                      );

    initial begin
        rst_n = 0;
        clk = 0;
        wr_en = 0;
        rd_en = 0;
        #10;
        rst_n = 1;
        #10;
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);

        dataTask(DIR_RD);
        dataTask(DIR_WR);
        dataTask(DIR_RD);
        dataTask(DIR_WR);
        dataTask(DIR_RD);
        dataTask(DIR_WR);
        #8;
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        dataTask(DIR_WR_RD);
        #8;
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        #8;
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        dataTask(DIR_WR);
        #8;
        dataTask(DIR_RD);
        dataTask(DIR_RD);
        dataTask(DIR_RD);
        dataTask(DIR_RD);
        dataTask(DIR_RD);
        dataTask(DIR_RD);
        dataTask(DIR_RD);
        dataTask(DIR_RD);
        #8;
        dataTask(DIR_RD);
        dataTask(DIR_RD);
        dataTask(DIR_RD);
    end

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0,syn_fifo_tb);
        //$monitor("%4d %d %d 0x%x %d 0x%x", $time, clk, wr_full, wr_data, rd_empty, data_out);
        #800;
        $dumpflush;
        $finish;
    end

    task dataTask;
        input reg [1:0] dir;
        begin
            if (dir == DIR_WR) begin
                wr_en = 1;
                rd_en = 0;
                wr_data = ($random) % 256;
                $display("DIR_WR");
                $display("wr_full:%d,wr_data:0x%x",wr_full,wr_data);
                #2;
                clk = 1;
                #2;
                clk = 0;
                $display("rd_empty:%d,data_out:0x%x",rd_empty,data_out);
            end
            else if (dir == DIR_RD) begin 
                wr_en = 0;
                rd_en = 1;
                wr_data = 0;
                $display("DIR_RD");
                $display("wr_full:%d,wr_data:0x%x",wr_full,wr_data);
                #2;
                clk = 1;
                #2;
                clk = 0;
                data_out = rd_data;
                $display("rd_empty:%d,data_out:0x%x",rd_empty,data_out);
            end
            else if (dir == DIR_RD) begin 
                wr_en = 0;
                rd_en = 1;
                wr_data = 0;
                $display("DIR_RD");
                $display("wr_full:%d,wr_data:0x%x",wr_full,wr_data);
                #2;
                clk = 1;
                #2;
                clk = 0;
                data_out = rd_data;
                $display("rd_empty:%d,data_out:0x%x",rd_empty,data_out);
            end
            else if (dir == DIR_WR_RD) begin 
            end
            else begin
                wr_en = 0;
                rd_en = 0;
                wr_data = ($random) % 256;
                $display("DIR_CLOSE");
                $display("wr_full:%d,wr_data:0x%x",wr_full,wr_data);
                #2;
                clk = 1;
                #2;
                clk = 0;
                data_out = rd_data;
                $display("rd_empty:%d,data_out:0x%x",rd_empty,data_out);
            end
        end
    endtask

endmodule

`resetall
