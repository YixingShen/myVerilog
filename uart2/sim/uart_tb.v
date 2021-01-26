//20210126 UART Transmitter/Receiver Test Bench

`timescale 1 ns / 1 ps
`default_nettype none

`define ASSERT(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

module uart_tb;
    parameter SYS_CLOCK = 50000000;
    parameter SYS_PERIOD = (10 ** 9) / SYS_CLOCK;
    parameter UART_BAUDRATE = SYS_CLOCK / 8;//115200;

    reg SysClock;
    reg ResetN;
    
    reg TxValid;
    reg [7:0] TxByte;
    wire TxSerial;
    wire TxDone;
    reg toggle;

    wire [7:0] RxByte;
    wire RxSerial;
    wire RxDone;

    assign RxSerial = TxSerial;
     
    uart_tx
    #(
        SYS_CLOCK,
        UART_BAUDRATE
    )
    uart_tx_inst
    (
        .i_ResetN(ResetN),
        .i_SysClock(SysClock),
        .i_TxValid(TxValid),
        .i_TxByte(TxByte),
        .o_TxSerial(TxSerial),
        .o_TxDone(TxDone)
    );

    uart_rx
    #(
        SYS_CLOCK,
        UART_BAUDRATE
    )
    uart_rx_inst
    (
        .i_ResetN(ResetN),
        .i_SysClock(SysClock),
        .o_RxByte(RxByte),
        .i_RxSerial(RxSerial),
        .o_RxDone(RxDone)
    );
    
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0,uart_tb);

        #(SYS_PERIOD*10);
        SysClock = 0;
        ResetN = 0;
        TxValid = 0;
        TxByte = 0;
        toggle = 0;
        
        repeat (10) begin
            #(SYS_PERIOD*1)
            @(negedge SysClock)
            ResetN = 1;
            #(SYS_PERIOD*10);
            @(negedge SysClock)
            
            TxByte = 8'h55;       
            //TxByte = $random / 256;        

            @(negedge SysClock)
            TxValid = 1;
            @(negedge SysClock)
            TxValid = 0;
            
            while (!TxDone) begin #1; end
            
            while (!RxDone) begin #1; end
            
            toggle = ~toggle;        
            
            if (TxByte == RxByte)
                $display("OK.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
            else
                $display("NG.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        end

        #(SYS_PERIOD*100);

        $dumpflush;
        $finish;
    end

    always begin
        #(SYS_PERIOD/2) SysClock = ~SysClock;
    end

endmodule
`resetall
