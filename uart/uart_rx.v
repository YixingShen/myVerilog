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

    parameter TIMER_COUNT_1 = (SYS_CLOCK / UART_BAUDRATE / 2);
    parameter TIMER_COUNT_2 = (SYS_CLOCK / UART_BAUDRATE);

    parameter IDLE      = 0;
    parameter START_BIT = 1;
    parameter DATA_BITS = 2;
    parameter STOP_BIT  = 3;

    reg [3:0] state, state_next;
    reg q1_RxSerial, q2_RxSerial;
    reg [7:0] RxByte; //LSB First

    reg TimerEna;
    wire TimerInt;
    reg [4:0] BitCount;
    wire [15:0] MaxTimerCount;
    reg db1,db2;
    reg [15:0] TimerCount;

    assign MaxTimerCount = (state == START_BIT) ? TIMER_COUNT_1 : TIMER_COUNT_2;
    assign TimerInt = (TimerCount == MaxTimerCount);
    assign o_RxByte = RxByte;
    
    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN || !TimerEna) begin
            TimerCount <= 16'd0;
        end
        else begin
            if (TimerCount == MaxTimerCount)
               TimerCount <= 16'd0;
            else
               TimerCount <= TimerCount + 16'd1;
        end
    end

    assign o_RxDone = (state == IDLE) || (state == STOP_BIT);

    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            q1_RxSerial <= 1'b1;
            q2_RxSerial <= 1'b1;
        end
        else begin
            q1_RxSerial <= i_RxSerial; //Meta Stable
            q2_RxSerial <= q1_RxSerial;
        end
    end
    
    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            state <= IDLE;
            db1 <= 0;
            db2 <= 0;
        end
        else begin
            if (state == START_BIT || state == DATA_BITS) begin
                state <= TimerInt ? state_next : state;
                db2 <= TimerInt ? ~db2 : db2;
            end
            else begin
                state <= state_next;
            end
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                state_next = (q2_RxSerial == 1'b0) ? START_BIT : IDLE;
            end
            START_BIT: begin
                state_next = DATA_BITS;
            end
            DATA_BITS: begin
                state_next = (BitCount == 4'd8) ? STOP_BIT : DATA_BITS;
            end
            STOP_BIT: begin
                state_next = (q2_RxSerial == 1'b0) ? START_BIT : IDLE;
            end
            default: begin
                state_next = IDLE;
            end
        endcase;
    end
        
    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            BitCount <= 4'd0;
            RxByte <= 8'd0;
            TimerEna <= 1'b0;
        end
        else begin
            if ((state == DATA_BITS) && (state_next == DATA_BITS) && (TimerInt)) begin
                RxByte[7:0] <= {q2_RxSerial,RxByte[7:1]};
                BitCount <= BitCount + 4'd1;
                db1 <= ~db1;
            end
            else if (state == IDLE || state == STOP_BIT) begin
                BitCount <= 4'd0;
                TimerEna <= 1'b0;
            end
            else if (state == START_BIT) begin
                TimerEna <= 1'b1;
            end
        end
    end

endmodule
