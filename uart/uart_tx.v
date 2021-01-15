//20210116 UART TX

`timescale 1 ns / 1 ps
`default_nettype none

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

    parameter TIMER_COUNT = (SYS_CLOCK / UART_BAUDRATE);

    parameter IDLE      = 0;
    parameter START_BIT = 1;
    parameter DATA_BITS = 2;
    parameter STOP_BIT  = 3;

    reg [3:0] state, state_next;

    reg TxSerial;
    reg TxValid;
    reg [7:0] TxByte; //LSB First
    reg [2:0] BitCount;

    reg TimerEna;
    wire TimerInt;
    wire [15:0] MaxTimerCount;
    reg [15:0] TimerCount;
    reg db1,db2;

    assign MaxTimerCount = TIMER_COUNT;
    assign TimerInt = (TimerCount == MaxTimerCount);
    
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

    assign o_TxSerial = TxSerial;
    assign o_TxDone = (state == IDLE) || (state == STOP_BIT);

    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            state <= IDLE;
            db1 <= 0;
            db2 <= 0;
        end
        else begin
            if (state >= START_BIT && state <= STOP_BIT) begin
                state <= TimerInt ? state_next : state;
                db2 <= TimerInt? ~db2 : db2;
            end
            else
                state <= state_next;
        end
    end

    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            TimerEna <= 1'b0;
            BitCount <= 3'd0;
        end
        else begin
            if (state == DATA_BITS) begin
                BitCount <= BitCount + TimerInt;
            end
            else if (state == START_BIT) begin
                TimerEna <= 1'b1;
                BitCount <= 3'd0;
                TxByte <= i_TxByte;
            end
            else if (state == IDLE) begin
                TimerEna <= 1'b0;
            end
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                TxSerial = 1'b1;
                state_next = i_TxValid ? START_BIT : IDLE;
            end
            START_BIT: begin
                TxSerial = 1'b0;
                state_next = DATA_BITS;
            end
            DATA_BITS: begin
                TxSerial = TxByte[BitCount];

                if (BitCount == 3'd7)
                    state_next = STOP_BIT;
                else
                    state_next = DATA_BITS;
            end
            STOP_BIT: begin
                TxSerial = 1'b1;
                state_next = i_TxValid ? START_BIT : IDLE;
            end
            default: begin
                TxSerial = 1'b1;
                state_next = IDLE;
            end
        endcase;
    end
    
endmodule
