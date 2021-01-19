//20210116 UART RX

`timescale 1 ns / 1 ps
`default_nettype none

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

    parameter MAX_TIMER_COUNT_HALF = (SYS_CLOCK / UART_BAUDRATE / 2);
    parameter MAX_TIMER_COUNT_FULL = (SYS_CLOCK / UART_BAUDRATE);

    parameter IDLE      = 2'd0;
    parameter START_BIT = 2'd1;
    parameter DATA_BITS = 2'd2;
    parameter STOP_BIT  = 2'd3;

    reg [1:0] state, state_next;
    reg q1_RxSerial, q2_RxSerial;
    reg [7:0] RxByte; //LSB First

    wire TimerInt;
    reg [4:0] BitCount;
    wire [$clog2(MAX_TIMER_COUNT_FULL):0] MaxTimerCount;
    reg [$clog2(MAX_TIMER_COUNT_FULL):0] TimerCount;

    assign MaxTimerCount = (state == START_BIT) ? MAX_TIMER_COUNT_HALF : MAX_TIMER_COUNT_FULL;
    assign TimerInt = (TimerCount == MaxTimerCount);
    assign o_RxByte = RxByte;
    
    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            TimerCount <= 0;
        end else begin
            if (TimerCount == MaxTimerCount || (state == IDLE && state_next == IDLE)) begin
                TimerCount <= 0;
            end else begin
                TimerCount <= TimerCount + 1;
            end
        end
    end

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
        end else begin
            if (state == START_BIT || state == DATA_BITS) begin
                state <= TimerInt ? state_next : state;
            end else begin
                state <= state_next;
            end
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                state_next = (q2_RxSerial == 0) ? START_BIT : IDLE;
            end
            START_BIT: begin
                state_next = DATA_BITS;
            end
            DATA_BITS: begin
                state_next = (BitCount == 8) ? STOP_BIT : DATA_BITS;
            end
            STOP_BIT: begin
                state_next = (q2_RxSerial == 0) ? START_BIT : IDLE;
            end
            default: begin
                state_next = IDLE;
            end
        endcase;
    end
        
    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            BitCount <= 0;
            RxByte <= 0;
        end else begin
            if (state == DATA_BITS && state_next == DATA_BITS) begin
                RxByte <= TimerInt ? {q2_RxSerial,RxByte[7:1]} : RxByte;
                BitCount <= TimerInt ? BitCount + 1 : BitCount;
            end else if (state == IDLE || state == STOP_BIT) begin
                BitCount <= 0;
            end
        end
    end

endmodule
`resetall
