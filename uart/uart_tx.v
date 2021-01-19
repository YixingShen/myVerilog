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

    parameter MAX_TIMER_COUNT = (SYS_CLOCK / UART_BAUDRATE);

    parameter IDLE      = 2'd0;
    parameter START_BIT = 2'd1;
    parameter DATA_BITS = 2'd2;
    parameter STOP_BIT  = 2'd3;

    reg [1:0] state, state_next;

    reg TxValid;
    reg [8:0] Dout; //LSB First
    reg [3:0] BitCount;

    wire TimerInt;
    reg [$clog2(MAX_TIMER_COUNT):0] TimerCount;

    assign TimerInt = (TimerCount == MAX_TIMER_COUNT);
    
    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            TimerCount <= 0;
        end else begin
            if (TimerCount == MAX_TIMER_COUNT || (state == IDLE && state_next == IDLE)) begin
               TimerCount <= 0;
            end else begin
               TimerCount <= TimerCount + 1;
            end
        end
    end

    assign o_TxSerial = (state == IDLE && state_next == IDLE) || state == STOP_BIT ? 1 : Dout[0];
    assign o_TxDone = (state == IDLE);

    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            state <= IDLE;
        end else begin
            if (state >= START_BIT && state <= STOP_BIT) begin
                state <= TimerInt ? state_next : state;
            end else begin
                state <= state_next;
            end
        end
    end

    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            Dout <= {i_TxByte,1'b0};
            BitCount <= 0;
        end else begin
            if (state == DATA_BITS)  begin
                BitCount <= TimerInt ? BitCount + 1 : BitCount;
            end else begin
                BitCount <= 0;
            end

            if (state == START_BIT || state == DATA_BITS) begin
                Dout <= TimerInt ? {Dout[0],Dout[8:1]} : Dout;
            end else begin
                Dout <= {i_TxByte,1'b0};
            end
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                state_next = i_TxValid ? START_BIT : IDLE;
            end
            START_BIT: begin
                state_next = DATA_BITS;
            end
            DATA_BITS: begin
                state_next = (BitCount == 7) ? STOP_BIT : DATA_BITS;
            end
            STOP_BIT: begin
                state_next = i_TxValid ? START_BIT : IDLE;
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end
endmodule
`resetall
