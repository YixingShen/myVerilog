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
    output reg [7:0] o_RxByte,
    input wire i_RxSerial,
    output wire o_RxDone
    );

    localparam MAX_CYCLE_CNT_HALF = ((SYS_CLOCK * 10 / UART_BAUDRATE / 2 + 5)) / 10 - 1;
    localparam MAX_CYCLE_CNT = ((SYS_CLOCK * 10 / UART_BAUDRATE + 5)) / 10  - 1;

    parameter IDLE      = 2'd0;
    parameter START_BIT = 2'd1;
    parameter DATA_BITS = 2'd2;
    parameter STOP_BIT  = 2'd3;

    reg [1:0] state;
    reg q1_RxSerial, q2_RxSerial;
    reg [7:0] RxByte; //LSB First
    reg [7:0] shift_reg;
    reg StopBit;

    reg [3:0] bit_count;
    reg [$clog2(MAX_CYCLE_CNT):0] cycle_count;
`ifdef DBG
    reg [7:0] dbg;
`endif

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
            bit_count <= 0;
            cycle_count <= 0;
            o_RxByte <= 0;
            StopBit <= 0;
            shift_reg <= 0;
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
                    if (cycle_count != MAX_CYCLE_CNT_HALF) begin
                        cycle_count <= cycle_count + 1;
`ifdef DBG
                        dbg[1] <= ~dbg[1];
`endif
                    end else begin
                        state <= DATA_BITS;
                        cycle_count <= 0;
                        bit_count <= 0;
                        StopBit <= 0;
`ifdef DBG
                        dbg[2] <= ~dbg[2];
`endif
                    end
                end
                DATA_BITS: begin
                    if (cycle_count != MAX_CYCLE_CNT) begin
                        cycle_count <= cycle_count + 1;
`ifdef DBG
                        dbg[3] <= ~dbg[3];
`endif
                    end else begin
                        if (bit_count != 8) begin
                            bit_count <= bit_count + 1;
                            shift_reg <= {q2_RxSerial,shift_reg[7:1]};
`ifdef DBG
                            dbg[4] <= ~dbg[4];
`endif
                        end else begin
                            state <= STOP_BIT;
                            o_RxByte <= shift_reg;
`ifdef DBG
                            dbg[5] <= ~dbg[5];
`endif
                        end

                        cycle_count <= 0;
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
                    cycle_count <= 0;
                    bit_count <= 0;
                end
            endcase
        end
    end

endmodule
`resetall
