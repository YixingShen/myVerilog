//20210126 UART Receiver 
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

module uart_rx_control_unit
    (
    input wire i_ResetN,
    input wire i_SysClock,
    input wire [3:0] i_bit_count,
    output wire o_RxDone,
    output reg o_Start,
    input wire i_RxSerial,
    output wire o_SynchRxSerial
    );

    parameter s_IDLE  = 1'b0;
    parameter s_RCVRS = 1'b1;

    reg state, state_next;
    reg q1_RxSerial, q2_RxSerial;

    assign o_SynchRxSerial = q2_RxSerial;
    assign o_RxDone = (state == s_IDLE) ? 1 : 0;

    always @(posedge i_SysClock, negedge i_ResetN) begin : SyncRxSerial
        if (!i_ResetN) begin
            q1_RxSerial <= 1;
            q2_RxSerial <= 1;
        end else begin
            q1_RxSerial <= i_RxSerial; //Meta Stable
            q2_RxSerial <= q1_RxSerial;
        end
    end

    always @(posedge i_SysClock) begin : UpdateStateMachine
        if (!i_ResetN) begin
            state <= s_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin : NextStateMachine
        o_Start = 0;
        state_next = s_IDLE;
        
        case (state)
            s_IDLE: begin  
                if (q2_RxSerial == 0) begin
                    o_Start = 1;
                    state_next = s_RCVRS;
                end
            end
            s_RCVRS: begin //b0,1,2,3,4,5,6,7,stop_bit
                if (i_bit_count != (`MAX_BIT_CNT + 1))
                    state_next = s_RCVRS;
            end
            default: begin
                state_next = s_IDLE;
            end
        endcase
    end

endmodule

module uart_rx_datapath_unit
    #(
    parameter SYS_CLOCK = 50000000,
    parameter UART_BAUDRATE = 115200
    )(
    input wire i_ResetN,
    input wire i_SysClock,
    output reg [7:0] o_RxByte,
    input wire i_Start,
    output reg [3:0] o_bit_count,
    input wire i_RxSerial
    );

    localparam MAX_CYCLE_CNT_HALF = ((SYS_CLOCK * 10 / UART_BAUDRATE / 2 + 5)) / 10 - 1;
    localparam MAX_CYCLE_CNT = ((SYS_CLOCK * 10 / UART_BAUDRATE + 5)) / 10  - 1;

    reg [7:0] shift_reg;
    reg handing;
    reg [$clog2(MAX_CYCLE_CNT):0] cycle_count;

    wire baudrate_half_period_cond;
    wire baudrate_period_cond;
    //reg StopBit;

    assign baudrate_half_period_cond = (cycle_count == MAX_CYCLE_CNT_HALF) && (o_bit_count == 0) ? 1 : 0;
    assign baudrate_period_cond = (cycle_count == MAX_CYCLE_CNT) && (o_bit_count != 0) ? 1 : 0;

    always @(posedge i_SysClock) begin : BaudRateGen
        if (!i_ResetN) begin
            cycle_count <= 0;
        end else begin
            if (baudrate_half_period_cond == 1 || baudrate_period_cond == 1 || handing == 0) begin
                cycle_count <= 0;
            end else begin
                cycle_count <= cycle_count + 1;
            end 
        end
    end

    always @(posedge i_SysClock) begin : SerialIn
        if (!i_ResetN) begin
            o_bit_count <= 0;
            shift_reg <= 0;
            handing <= 0;
            //StopBit <= 0;
            o_RxByte <= 0;
        end else begin
            if (i_Start) begin
                o_bit_count <= 0;
                handing <= 1;
            end else if (baudrate_half_period_cond == 1) begin
                o_bit_count <= o_bit_count + 1;
            end else if (baudrate_period_cond == 1) begin
                shift_reg <= {i_RxSerial,shift_reg[7:1]};
                o_bit_count <= o_bit_count + 1;

                if (o_bit_count == `MAX_BIT_CNT) begin
                    handing <= 0;
                    //StopBit <= i_RxSerial;
                    o_RxByte <= shift_reg;
                end
            end 
        end
    end

endmodule

module uart_rx
    #(
    parameter SYS_CLOCK = 50000000,
    parameter UART_BAUDRATE = 115200
    )(
    input wire i_ResetN,
    input wire i_SysClock,
    output wire [7:0] o_RxByte,
    input wire i_RxSerial,
    output wire o_RxDone
    );

    wire Start;
    wire synchRxSerial;
    wire [3:0] bit_count;
    
    uart_rx_control_unit
    ctl_inst
    (
        .i_ResetN(i_ResetN),
        .i_SysClock(i_SysClock),
        .i_bit_count(bit_count),
        .o_RxDone(o_RxDone),
        .o_Start(Start),
        .i_RxSerial(i_RxSerial),
        .o_SynchRxSerial(synchRxSerial)
    );

    uart_rx_datapath_unit
    #(
        SYS_CLOCK,
        UART_BAUDRATE
    )
    dp_inst
    (
        .i_ResetN(i_ResetN),
        .i_SysClock(i_SysClock),
        .o_RxByte(o_RxByte),
        .i_Start(Start),
        .o_bit_count(bit_count),
        .i_RxSerial(synchRxSerial)
    );

endmodule
`resetall
