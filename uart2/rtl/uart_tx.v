//20210126 UART Transmitter
// synthesis translate_off
`timescale 1 ns / 1 ps
// synthesis translate_on
`default_nettype none
`define MAX_BIT_CNT 9

`define ASSERT(signal, value) \
    if (signal !== value) begin \
        $display("ASSERTION FAILED in %m: signal != value"); \
        $finish; \
    end

module uart_tx_control_unit
    (
    input wire i_ResetN,
    input wire i_SysClock,
    input wire i_TxValid,
    input wire [3:0] i_bit_count,
    output wire o_TxDone,
    output reg o_Start,
    output reg o_Shift
    );

    parameter s_IDLE  = 1'b0;
    parameter s_TRANS = 1'b1;

    assign o_TxDone = (state == s_IDLE) ? 1 : 0;

    reg state, state_next;

    always @(posedge i_SysClock) begin : UpdateStateMachine
        if (!i_ResetN) begin
            state <= s_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin : NextStateMachine
        o_Start = 0;
        o_Shift = 0;
        state_next = s_IDLE;
        
        case (state)
            s_IDLE: begin
                if (i_TxValid) begin
                    o_Start = 1;
                    state_next = s_TRANS;
                end
            end
            s_TRANS: begin //b0,1,2,3,4,5,6,7,stop_bit
                if (i_bit_count != (`MAX_BIT_CNT + 1))
                    state_next = s_TRANS;

                if (i_bit_count >= 1 && i_bit_count <= (`MAX_BIT_CNT-1))
                    o_Shift = 1;
            end
            default: begin
                state_next = s_IDLE;
            end
        endcase
    end

endmodule

module uart_tx_datapath_unit
    #(
    parameter SYS_CLOCK = 50000000,
    parameter UART_BAUDRATE = 115200
    )(
    input wire i_ResetN,
    input wire i_SysClock,
    input wire [7:0] i_TxByte,
    input wire i_Shift,
    input wire i_Start,
    output reg [3:0] o_bit_count,
    output wire o_TxSerial
    );

    localparam MAX_CYCLE_CNT = ((SYS_CLOCK * 10 / UART_BAUDRATE + 5) / 10) - 1;

    reg [7:0] TxByte;
    reg [8:0] shift_reg;
    reg handing;
    reg [$clog2(MAX_CYCLE_CNT):0] cycle_count;
    wire baudrate_period_cond;

    assign o_TxSerial = shift_reg[0];
    assign baudrate_period_cond = (cycle_count == MAX_CYCLE_CNT) ? 1 : 0;
    
    always @(posedge i_SysClock) begin : BaudRateGen
        if (!i_ResetN) begin
            cycle_count <= 0;
        end else begin
            if (baudrate_period_cond == 1 || handing == 0) begin
                cycle_count <= 0;
            end else begin
                cycle_count <= cycle_count + 1;
            end 
        end
    end
    
    always @(posedge i_SysClock) begin : SerialOut
        if (!i_ResetN) begin
            o_bit_count <= 0;
            shift_reg <= {9{1'b1}};
            TxByte <= 0;
            handing <= 0;
        end else begin
            if (i_Start) begin
                o_bit_count <= 0;
                shift_reg[0] <= 0;
                TxByte <= i_TxByte;
                handing <= 1;
            end if (baudrate_period_cond == 1) begin
                if (handing == 1) begin
                    shift_reg <= (i_Shift == 1) ? {shift_reg[0],shift_reg[8:1]} : {1'b1,TxByte};
                    o_bit_count <= o_bit_count + 1;
                end
                
                if (o_bit_count == `MAX_BIT_CNT)
                    handing = 0;
            end 
        end
    end

endmodule

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

    wire Start;
    wire Shift;
    wire [3:0] bit_count;
    
    uart_tx_control_unit
    ctl_inst
    (
        .i_ResetN(i_ResetN),
        .i_SysClock(i_SysClock),
        .i_TxValid(i_TxValid),
        .i_bit_count(bit_count),
        .o_TxDone(o_TxDone),
        .o_Start(Start),
        .o_Shift(Shift)
    );

    uart_tx_datapath_unit
    #(
        SYS_CLOCK,
        UART_BAUDRATE
    )
    dp_inst
    (
        .i_ResetN(i_ResetN),
        .i_SysClock(i_SysClock),
        .i_TxByte(i_TxByte),
        .i_Start(Start),
        .i_Shift(Shift),
        .o_bit_count(bit_count),
        .o_TxSerial(o_TxSerial)
    );

endmodule
`resetall
