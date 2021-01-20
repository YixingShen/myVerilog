//20210120 UART RX

`timescale 1 ns / 1 ps
`default_nettype none
`define DBG

module uart_rx
    #(
    parameter SYS_CLOCK = 50000000,
    parameter UART_BAUDRATE = 115200
    )(
    input wire i_ResetN,
    input wire i_SysClock,
    input wire i_RxValid,
    output wire [7:0] o_RxByte,
    input wire i_RxSerial,
    output wire o_RxDone
    );

    parameter MAX_CYCLE_CNT_HALF = (SYS_CLOCK / UART_BAUDRATE / 2);
    parameter MAX_CYCLE_CNT_FULL = (SYS_CLOCK / UART_BAUDRATE);

    parameter IDLE      = 2'd0;
    parameter START_BIT = 2'd1;
    parameter DATA_BITS = 2'd2;
    parameter STOP_BIT  = 2'd3;

    reg [1:0] state;
    reg q1_RxSerial, q2_RxSerial;
    reg [7:0] RxByte; //LSB First
    reg StopBit;

    reg [3:0] bit_cnt;
    reg [$clog2(MAX_CYCLE_CNT_FULL):0] cycle_cnt;
`ifdef DBG
    reg [7:0] dbg;
`endif

    assign o_RxByte = RxByte;
    assign o_RxDone = (state == IDLE) || (state == STOP_BIT);

    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            q1_RxSerial <= 1;
            q2_RxSerial <= 1;
        end else begin
            q1_RxSerial <= i_RxSerial; //Meta Stable
            q2_RxSerial <= q1_RxSerial;
        end
    end
    
    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            state <= IDLE;
            bit_cnt <= 0;
            cycle_cnt <= 0;
            RxByte <= 0;
            StopBit <= 0;
`ifdef DBG
            dbg <= 0;
`endif
        end else begin
            case (state)
                IDLE: begin
                    state <= (q2_RxSerial == 0) ? START_BIT : IDLE;
`ifdef DBG
                    dbg[0] <= ~dbg[0];
`endif
                end
                START_BIT: begin
                    if (cycle_cnt != MAX_CYCLE_CNT_HALF) begin
                        cycle_cnt <= cycle_cnt + 1;
`ifdef DBG
                        dbg[1] <= ~dbg[1];
`endif
                    end else begin
                        state <= DATA_BITS;
                        cycle_cnt <= 0;
                        bit_cnt <= 0;
                        StopBit <= 0;
`ifdef DBG
                        dbg[2] <= ~dbg[2];
`endif
                    end
                end
                DATA_BITS: begin
                    if (cycle_cnt != MAX_CYCLE_CNT_FULL) begin
                        cycle_cnt <= cycle_cnt + 1;
`ifdef DBG
                        dbg[3] <= ~dbg[3];
`endif
                    end else begin
                        if (bit_cnt != 8) begin
                            bit_cnt <= bit_cnt + 1;
                            RxByte <= {q2_RxSerial,RxByte[7:1]};
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
                    state <= (q2_RxSerial == 0) ? START_BIT : IDLE;
                    StopBit <= q2_RxSerial;
`ifdef DBG
                    dbg[7] <= ~dbg[7];
`endif
                end
                default: begin
                    state <= IDLE;
                    cycle_cnt <= 0;
                    bit_cnt <= 0;
                end
            endcase
        end
    end

endmodule
`resetall
