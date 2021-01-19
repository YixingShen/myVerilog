//20210116 UART TX/RX Test Bench

`timescale 1 ns / 1 ps
`default_nettype none

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

module uart_tb;
    parameter SYS_CLOCK = 50000000;
    parameter SYS_PERIOD = (10 ** 9) / SYS_CLOCK;
    parameter UART_BAUDRATE = SYS_CLOCK/7;//115200;
    //parameter UART_BAUDRATE = 115200;

    reg SysClock;
    reg ResetN;
    
    reg TxValid;
    reg [7:0] TxByte;
    wire TxSerial;
    wire TxDone;
    integer Delay;

    reg RxValid;
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
        .i_RxValid(RxValid),
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
        RxValid = 0;
        
        #(SYS_PERIOD*1);
        @(negedge SysClock);
        ResetN = 1;
        #(SYS_PERIOD*10);

        TxByte = 8'h55;
        TxValid = 1;
        @(posedge SysClock);
        @(posedge SysClock);
        TxValid = 0;
        while (!TxDone) begin #1; end;
        while (!RxDone) begin #1; end;

        if (TxByte != RxByte)
            $display("NG.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        else
            $display("OK.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        TxByte = 8'h00;
        TxValid = 1;
        @(posedge SysClock);
        @(posedge SysClock);
        TxValid = 0;
        while (!TxDone) begin #1; end;
        while (!RxDone) begin #1; end;
        
        if (TxByte != RxByte)
            $display("NG.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        else
            $display("OK.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        
        TxByte = 8'hFF;
        TxValid = 1;
        @(posedge SysClock);
        @(posedge SysClock);
        TxValid = 0;
        while (!TxDone) begin #1; end;
        while (!RxDone) begin #1; end;
        
        if (TxByte != RxByte)
            $display("NG.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        else
            $display("OK.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        
        TxByte = 8'hAA;
        TxValid = 1;
        @(posedge SysClock);
        @(posedge SysClock);
        TxValid = 0;
        while (!TxDone) begin #1; end;
        while (!RxDone) begin #1; end;
        
        if (TxByte != RxByte)
            $display("NG.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        else
            $display("OK.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
            
        repeat (10) begin
            TxByte = ($random) % 256;
            TxValid = 1;
            @(posedge SysClock);
            @(posedge SysClock);
            TxValid = 0;
            while (!TxDone) begin #1; end;
            while (!RxDone) begin #1; end;
            
            if (TxByte != RxByte)
                $display("NG.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
            else
                $display("OK.TxByte:0x%2X,RxByte:0x%2X",TxByte,RxByte);
        end

        $dumpflush;
        $finish;
    end

    always begin
        #(SYS_PERIOD/2) SysClock = ~SysClock;
    end

endmodule
`resetall
