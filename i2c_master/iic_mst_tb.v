`timescale 1 ns / 100 ps
`default_nettype none

module iic_mst_tb;
    parameter SYS_CLOCK = 50000000;
    parameter SYS_PERIOD = (10 ** 9) / SYS_CLOCK;
    
    parameter CMD_NULL    = 0;
    parameter CMD_START   = 1;
    parameter CMD_WRDATA  = 2;
    parameter CMD_RDDATA  = 3;
    parameter CMD_STOP    = 4;
    parameter CMD_PRE_START = 5;
    
    reg [7:0] slvRxByte;
    reg ResetN;
    reg SysClock;
    reg mstCmdValid;
    reg [3:0] mstCmd;
    reg [7:0] mstTxByte;
    wire [7:0] mstRxByte;
    wire mstDone;
    wire mstGetAck;
    reg mstSetAck;
    reg [7:0] slvTxByte, slvTxByte_r;
    reg slvSCL_oe;
    reg slvSDA_oe;
    reg slvSCL_dout;
    reg slvSDA_dout;
    reg slvSCL_in;
    reg slvSDA_in;
    reg slvGetAck;
    reg slvSetAck;
    
    //tri1 slvSCL_Pin; //tri status pull high
    //tri1 slvSDA_Pin; //tri status pull high
    wire slvSCL_Pin;
    wire slvSDA_Pin;

    pullup (slvSCL_Pin);
    pullup (slvSDA_Pin);

    assign slvSCL_Pin = slvSCL_oe ? slvSCL_dout : 1'bz;
    assign slvSDA_Pin = slvSDA_oe ? slvSDA_dout : 1'bz;

    iic_mst 
    #(
        SYS_CLOCK,
        100000
    )
    iic_mst_inst
    (
        .i_ResetN(ResetN),
        .i_SysClock(SysClock),
        .i_CmdValid(mstCmdValid),
        .i_Cmd(mstCmd),
        .i_TxByte(mstTxByte),
        .o_RxByte(mstRxByte),
        .o_Done(mstDone),
        .io_SCL(slvSCL_Pin),
        .io_SDA(slvSDA_Pin),
        .o_GetAck(mstGetAck),
        .i_SetAck(mstSetAck)
    );

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0,iic_mst_tb);
        SysClock = 0;
        ResetN = 0;
        slvSCL_oe = 0;
        slvSDA_oe = 0;
        slvSCL_dout = 0;
        slvSDA_dout = 0;
        slvSetAck = 0;
        mstTxByte = 8'h00;
        mstCmdValid = 0;
        mstSetAck = 0;

        #(SYS_PERIOD*10);
        ResetN = 1;
        #(SYS_PERIOD*100);
        
        $display("------Master Read Slave Write Test------");
        repeat (10) begin
            mstCmd = CMD_START;
            mstCmdValid = 1;
            @(negedge SysClock);
            @(negedge SysClock);
            mstCmdValid = 0;

            while (mstDone == 0) #SYS_PERIOD; 

            mstCmd = CMD_RDDATA;
            slvTxByte_r = $random % 256;
            slvTxByte = slvTxByte_r;
            mstSetAck = $random & 1'b1;
            mstCmdValid = 1;
            @(negedge SysClock);
            @(negedge SysClock);
            mstCmdValid = 0;

            repeat (8) begin
                while (slvSCL_Pin == 1) #1;
                slvSDA_oe = slvTxByte_r[7] == 0 ? 1 : 0;
                slvTxByte_r = {slvTxByte_r[6:0],slvTxByte_r[7]};
                while (slvSCL_Pin == 0) #1;
            end

            @(negedge slvSCL_Pin); //8th clock Falling
            slvSDA_oe = 0;
            @(posedge slvSCL_Pin); //9th clock Raising
            slvGetAck = slvSDA_Pin;
            @(negedge slvSCL_Pin); //9th clock Falling

            if (mstSetAck == slvGetAck)
                $display("OK. mstSetAck=0x%02X slvGetAck=0x%02X", mstSetAck, slvGetAck);
            else
                $display("NG. mstSetAck=0x%02X slvGetAck=0x%02X", mstSetAck, slvGetAck);
            
            if (mstRxByte == slvTxByte)
                $display("OK. mstRxByte=0x%02X slvTxByte=0x%02X", mstRxByte, slvTxByte);
            else
                $display("NG. mstRxByte=0x%02X slvTxByte=0x%02X", mstRxByte, slvTxByte);

            while (mstDone == 0) #SYS_PERIOD;

            mstCmd = CMD_RDDATA;
            slvTxByte_r = $random % 256;
            slvTxByte = slvTxByte_r;
            mstCmdValid = 1;
            @(negedge SysClock);
            @(negedge SysClock);
            mstCmdValid = 0;

            repeat (8) begin
                while (slvSCL_Pin == 1) #1;
                slvSDA_oe = slvTxByte_r[7] == 0 ? 1 : 0;
                slvTxByte_r = {slvTxByte_r[6:0],slvTxByte_r[7]};
                while (slvSCL_Pin == 0) #1;
            end

            while (mstDone == 0) #SYS_PERIOD; 
            
            if (mstRxByte == slvTxByte)
                $display("OK. mstRxByte=0x%02X slvTxByte=0x%02X", mstRxByte, slvTxByte);
            else
                $display("NG. mstRxByte=0x%02X slvTxByte=0x%02X", mstRxByte, slvTxByte);

            mstCmd = CMD_STOP;
            mstCmdValid = 1;
            @(negedge SysClock);
            @(negedge SysClock);
            mstCmdValid = 0;

            while (mstDone == 0) #SYS_PERIOD;
        end

        $display("------Master Write Slave Read Test------");
        repeat (10) begin
            mstCmd = CMD_START;
            mstCmdValid = 1;
            @(negedge SysClock);
            @(negedge SysClock);
            mstCmdValid = 0;

            ////Slave Clock Down
            //#(SYS_PERIOD*100);
            //slvSCL_oe = 1;
            //#(SYS_PERIOD*100);
            //slvSCL_oe = 0;
            
            while (mstDone == 0) #SYS_PERIOD; 

            mstCmd = CMD_WRDATA;
            mstTxByte = $random % 256;
            slvSetAck = $random & 1'b1;
            slvRxByte = 8'h00;
            mstCmdValid = 1;
            @(negedge SysClock);
            @(negedge SysClock);
            mstCmdValid = 0;

            repeat (8) begin
                while (slvSCL_Pin == 1) #1;
                ////Slave Clock Down 
                //slvSCL_oe = 1;
                //#(SYS_PERIOD*500);
                //slvSCL_oe = 0;
                while (slvSCL_Pin == 0) #1;
                
                slvRxByte = {slvRxByte[6:0],slvSDA_Pin};
            end

            @(negedge slvSCL_Pin); //8th clock Falling
            slvSDA_oe = slvSetAck == 0 ? 1 : 0;
            
            @(posedge slvSCL_Pin); //9th clock Raising
            @(negedge slvSCL_Pin); //9th clock Falling
            slvSDA_oe = 0;

            if (mstGetAck == slvSetAck)
                $display("OK. mstGetAck=0x%02X slvSetAck=0x%02X", mstGetAck, slvSetAck);
            else
                $display("NG. mstGetAck=0x%02X slvSetAck=0x%02X", mstGetAck, slvSetAck);

            while (mstDone == 0) #SYS_PERIOD; 

            if (mstTxByte == slvRxByte)
                $display("OK. mstTxByte=0x%02X slvRxByte=0x%02X", mstTxByte, slvRxByte);
            else
                $display("NG. mstTxByte=0x%02X slvRxByte=0x%02X", mstTxByte, slvRxByte);

            mstCmd = CMD_WRDATA;
            mstTxByte = $random % 256;
            slvSetAck = $random & 1'b1;
            slvRxByte = 8'h00;
            mstCmdValid = 1;
            @(negedge SysClock);
            @(negedge SysClock);
            mstCmdValid = 0;

            repeat (8) begin
                @(posedge slvSCL_Pin); //1-8th clock Raising
                slvRxByte <= {slvRxByte[6:0],slvSDA_Pin};
            end

            @(negedge slvSCL_Pin); //8th clock Falling
            slvSDA_oe = slvSetAck == 0 ? 1 : 0;
            
            @(posedge slvSCL_Pin); //9th clock Raising
            @(negedge slvSCL_Pin); //9th clock Falling
            slvSDA_oe = 0;
            
            if (mstGetAck == slvSetAck)
                $display("OK. mstGetAck=0x%02X slvSetAck=0x%02X", mstGetAck, slvSetAck);
            else
                $display("NG. mstGetAck=0x%02X slvSetAck=0x%02X", mstGetAck, slvSetAck);
            
            while (mstDone == 0) #SYS_PERIOD; 
            
            if (mstTxByte == slvRxByte)
                $display("OK. mstTxByte=0x%02X slvRxByte=0x%02X", mstTxByte, slvRxByte);
            else
                $display("NG. mstTxByte=0x%02X slvRxByte=0x%02X", mstTxByte, slvRxByte);

            mstCmd = CMD_STOP;
            mstCmdValid = 1;
            @(negedge SysClock);
            @(negedge SysClock);
            mstCmdValid = 0;

            while (mstDone == 0) #SYS_PERIOD;
        end

       #(SYS_PERIOD*100);
       $dumpflush;
       $finish;
    end

    always begin
        #(SYS_PERIOD/2) SysClock = ~SysClock;
    end

endmodule
