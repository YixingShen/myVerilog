//20210120 UART TX

`timescale 1 ns / 1 ps
`default_nettype none
//`define DBG

module uart_tx
    #(
    parameter SYS_CLOCK = 50000000,
    parameter UART_BAUDRATE = 115200
    )(
    input wire i_ResetN,
    input wire i_SysClock,
    input wire i_TxValid,
    input wire [7:0] i_TxByte,
    output wire o_TxSerial,
    output wire o_TxDone
    );

    parameter MAX_CYCLE_CNT = (SYS_CLOCK / UART_BAUDRATE);

    parameter IDLE      = 2'd0;
    parameter START_BIT = 2'd1;
    parameter DATA_BITS = 2'd2;
    parameter STOP_BIT  = 2'd3;

    reg [1:0] state;
    reg TxSerial;
    reg [7:0] Dout;
    reg [3:0] bit_cnt;
    reg [$clog2(MAX_CYCLE_CNT)] cycle_cnt;
`ifdef DBG
    reg [7:0] dbg;
`endif

    assign o_TxSerial = TxSerial;
    assign o_TxDone = (state == IDLE);

    always @(*) begin
        case (state)
            DATA_BITS: TxSerial = Dout[0];
            START_BIT: TxSerial = 0;
            default: TxSerial = 1;
        endcase
    end

    always @(posedge i_SysClock) begin
        if (!i_ResetN) begin
            state <= IDLE;
            cycle_cnt <= 0;
            bit_cnt <= 0;
`ifdef DBG
            dbg <= 0;
`endif
        end else begin
            case (state)
                IDLE: begin
                    state <= i_TxValid ? START_BIT : IDLE;
                    cycle_cnt <= 0;
`ifdef DBG
                    dbg[0] <= ~dbg[0];
`endif
                end
                START_BIT: begin
                    if (cycle_cnt != MAX_CYCLE_CNT) begin
                        cycle_cnt <= cycle_cnt + 1;
                        Dout <= i_TxByte;
`ifdef DBG
                        dbg[1] <= ~dbg[1];
`endif
                    end else begin
                        cycle_cnt <= 0;
                        bit_cnt <= 0;
                        state <= DATA_BITS;
`ifdef DBG
                        dbg[2] <= ~dbg[2];
`endif
                    end
                end
                DATA_BITS: begin
                    if (cycle_cnt != MAX_CYCLE_CNT) begin
                        cycle_cnt <= cycle_cnt + 1;
`ifdef DBG
                        dbg[3] <= ~dbg[3];
`endif
                    end else begin
                        if (bit_cnt != 7) begin //0,1,2,3,..,7
                            bit_cnt <= bit_cnt + 1;
                            Dout <= {Dout[0],Dout[7:1]};
`ifdef DBG
                            dbg[4] <= ~dbg[4];
`endif
                        end else begin
                            state <= STOP_BIT;
`ifdef DBG
                            dbg[5] <= ~dbg[5];
`endif
                        end
                        
                        cycle_cnt <= 0;
                    end
                end
                STOP_BIT: begin
                    if (cycle_cnt != MAX_CYCLE_CNT) begin
                        cycle_cnt <= cycle_cnt + 1;
`ifdef DBG
                        dbg[5] <= ~dbg[5];
`endif
                    end else begin
                        state <= IDLE;
                        cycle_cnt <= 0;
`ifdef DBG
                        dbg[6] <= ~dbg[6];
`endif
                    end
                end
                default: begin
                    cycle_cnt <= 0;
                    bit_cnt <= 0;
`ifdef DBG
                    dbg[7] <= ~dbg[7];
`endif
                end
            endcase
        end
    end

endmodule
`resetall
