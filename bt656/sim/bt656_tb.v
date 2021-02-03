//20210202 BT656 Test Bench

`timescale 1 ns / 100 ps
`default_nettype none

`define _TIMING_480I60_
//`define _TIMING_720P30_
//`define _TIMING_OTHER_

`define ASSERT(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

module bt656_tb;

`ifdef _TIMING_OTHER_
    //Other
    parameter SYS_CLOCK         = 27000000;
    parameter SYS_PERIOD        = (10 ** 9) / SYS_CLOCK;
    parameter PIXEL_CLOCK       = 27000000;
    parameter INTERLACE         = 0; //0: Progressive; 1: Interlace
    parameter FIRST_FIELD       = 0; //0: ODD; 1: EVEN
    parameter FIRST_LINE        = 0;
    parameter HACT_PIXELS       = 100; 
    parameter HBLK_PIXELS       = 40; 
    parameter VACT_LINES_F1     = 80; 
    parameter VBLK_LINES_F1_TOP = 12;
    parameter VBLK_LINES_F1_BOT = 4;
    parameter VACT_LINES_F2     = 80; 
    parameter VBLK_LINES_F2_TOP = 12;
    parameter VBLK_LINES_F2_BOT = 5;
`endif

`ifdef _TIMING_480I60_
    //480I60@27MHz
    parameter SYS_CLOCK         = 27000000;
    parameter SYS_PERIOD        = (10 ** 9) / SYS_CLOCK;
    parameter PIXEL_CLOCK       = 27000000;
    parameter INTERLACE         = 1; //0: Progressive; 1: Interlace
    parameter FIRST_FIELD       = 1; //0: ODD; 1: EVEN
    parameter FIRST_LINE        = (VACT_LINES_F2 + VBLK_LINES_F2_TOP + VBLK_LINES_F2_BOT - 1) - 3 + 1; 
    parameter HACT_PIXELS       = 720*2;
    parameter HBLK_PIXELS       = (19+62+57)*2;
    parameter VACT_LINES_F1     = 240;
    parameter VBLK_LINES_F1_TOP = 18;
    parameter VBLK_LINES_F1_BOT = 4;
    parameter VACT_LINES_F2     = 240; 
    parameter VBLK_LINES_F2_TOP = 18;
    parameter VBLK_LINES_F2_BOT = 5;
`endif

`ifdef _TIMING_720P30_
    //720P30@74.25MHz
    parameter SYS_CLOCK         = 74250000;
    parameter SYS_PERIOD        = (10 ** 9) / SYS_CLOCK;
    parameter PIXEL_CLOCK       = 74250000;
    parameter INTERLACE         = 0; //0: Progressive; 1: Interlace
    parameter FIRST_FIELD       = 0; //0: ODD; 1: EVEN
    parameter FIRST_LINE        = 0;
    parameter HACT_PIXELS       = 1280*2; 
    parameter HBLK_PIXELS       = (110+40+220)*2; 
    parameter VACT_LINES_F1     = 720; 
    parameter VBLK_LINES_F1_TOP = 25;
    parameter VBLK_LINES_F1_BOT = 5;
    parameter VACT_LINES_F2     = 720; 
    parameter VBLK_LINES_F2_TOP = 25;
    parameter VBLK_LINES_F2_BOT = 5;
`endif

    reg SysClock;
    reg ResetN;
    reg TxValid;
    wire [7:0] Data;
    wire PixelClock;
    wire Vsignal;
    wire Hsignal;
    wire Fsignal;
    reg InterlaceMode;
    reg [15:0] FirstLine;
    reg FirstField; //0: ODD; 1: EVEN

    bt656_tx
    #(
        SYS_CLOCK,
        PIXEL_CLOCK,
        HACT_PIXELS,
        HBLK_PIXELS,
        VACT_LINES_F1,
        VBLK_LINES_F1_TOP,
        VBLK_LINES_F1_BOT,
        VACT_LINES_F2,
        VBLK_LINES_F2_TOP,
        VBLK_LINES_F2_BOT
    )
    bt656_tx_inst
    (
        .i_ResetN(ResetN),
        .i_SysClock(SysClock),
        .i_TxValid(TxValid),
        .i_InterlaceMode(InterlaceMode),
        .i_FirstField(FirstField),
        .i_FirstLine(FirstLine),
        .o_Data(Data),
        .o_PixelClock(PixelClock),
        .o_Vsignal(Vsignal),
        .o_Hsignal(Hsignal),
        .o_Fsignal(Fsignal)
    );

    initial begin
        $dumpfile("sim.fst");
        $dumpvars(0,bt656_tb);

        #(SYS_PERIOD*10);
        SysClock = 0;
        ResetN = 0;
        TxValid = 0;
        InterlaceMode = INTERLACE;
        FirstLine = FIRST_LINE;
        FirstField = FIRST_FIELD;
        
        #(SYS_PERIOD*100);
        ResetN = 1;
        
        #(SYS_PERIOD*100);
        TxValid = 1;

        //#(SYS_PERIOD*4000000);
        //#(SYS_PERIOD*40000);

        @(posedge Vsignal)
        @(negedge Vsignal)
        @(posedge Vsignal)
        @(negedge Vsignal)

        $dumpflush;
        $finish;
    end

    always begin
        #(SYS_PERIOD/2) SysClock = ~SysClock;
    end

endmodule
`resetall
