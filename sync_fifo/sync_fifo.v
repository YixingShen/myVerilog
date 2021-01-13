`timescale 1 ns / 1 ps
`default_nettype none
`define dbg_wr_data_illegal

module sync_fifo
    #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
    )(
    clk,
    rst_n,
    wr_en,
    wr_full,
    wr_data,
    rd_en,
    rd_empty,
    rd_data,
    );    

    input wire clk;
    input wire rst_n;
    input wire wr_en;
    output wire wr_full;
    input wire [DATA_WIDTH-1:0] wr_data;
    input wire rd_en;
    output wire rd_empty;
    output reg [DATA_WIDTH-1:0] rd_data;

`ifdef dbg_wr_data_illegal
    reg [DATA_WIDTH-1:0] dbg_wr_data_illegal;
`endif
    reg [DATA_WIDTH-1:0] fifo_mem [(1 << ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0] qCount;
    wire enqueue;
    wire dequeue;

    assign wr_full  = (~rst_n) ? 1'b0 : (qCount == (1 << ADDR_WIDTH));
    assign rd_empty = (~rst_n) ? 1'b1 : (qCount == {ADDR_WIDTH{1'b0}});
    assign enqueue = wr_en && (~wr_full);
    assign dequeue = rd_en && (~rd_empty);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            qCount <= {ADDR_WIDTH{1'b0}};
            rd_data <= {DATA_WIDTH{1'bz}};
        end
        else begin
            case ({enqueue,dequeue})
                2'b11: begin //enqueue,dequeue
                    rd_data <= fifo_mem[rd_ptr];
                    fifo_mem[wr_ptr] <= wr_data;
                end
                2'b10: begin //enqueue
                    fifo_mem[wr_ptr] <= wr_data;
                    rd_data <= {DATA_WIDTH{1'bz}};
                end
                2'b01: begin //dequeue
                    rd_data <= fifo_mem[rd_ptr];
                end
                default: begin //do nothing
                    rd_data <= {DATA_WIDTH{1'bz}};
`ifdef dbg_wr_data_illegal
                    dbg_wr_data_illegal <= wr_data;
`endif
                end
            endcase
            
            qCount <= qCount + (enqueue - dequeue);
            wr_ptr <= wr_ptr + enqueue;
            rd_ptr <= rd_ptr + dequeue;
        end
    end

endmodule

`resetall
