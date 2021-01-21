`timescale 1 ns / 1 ps
`default_nettype none

//      4u   1.3u 4.7u    4u   1.3u 4.7u     4u  1.3u 4.7u  
//    |-----|           |-----|           |-----|            
//    |     |           |     |           |     |           
//____|     |__|________|     |__|________|     |__|________
//
//       max 3.45u    250ns setup
//          <---->    <->
//          <--> 300ns hold

module iic_mst
    #(
    parameter SYS_CLOCK = 50000000,
    parameter IIC_CLOCK = 100000 //100kHz
    )(
    input wire i_ResetN,
    input wire i_SysClock,
    input wire i_CmdValid,
    input wire [3:0] i_Cmd,
    input wire [7:0] i_TxByte,
    //output reg [7:0] o_RxByte,
    output wire [7:0] o_RxByte,
    output wire o_Done,
    inout wire io_SCL,
    inout wire io_SDA,
    output wire o_GetAck,
    input wire i_SetAck
    );

    parameter IIC_STRENTCH_MAX_CNT = (8 * SYS_CLOCK / IIC_CLOCK);
    parameter IIC_SCL_PERIOD_MAX_CNT = (SYS_CLOCK / IIC_CLOCK) / 2; //5u

    parameter CMD_NULL    = 0;
    parameter CMD_START   = 1;
    parameter CMD_WRDATA  = 2;
    parameter CMD_RDDATA  = 3;
    parameter CMD_STOP    = 4;
    parameter CMD_PRE_START = 5;

    reg SCL_oe, SDA_oe;//, SCL_d, SDA_d;
    wire SCL_in, SDA_in;
    reg CmdNext;
    reg [$clog2(IIC_SCL_PERIOD_MAX_CNT):0] cycle_cnt;
    reg [$clog2(IIC_STRENTCH_MAX_CNT):0] waitSCL_cnt;

    wire readCmd;
    reg [3:0] bit_cnt;
    reg [7:0] TxByte;
    reg [7:0] RxByte;
    reg SetAck;
    reg GetAck;
    reg [3:0] Cmd;
    wire clockStretchCond;
    wire iicSCLPreiodDiv1Cond;
    wire iicSCLPreiodDiv2Cond;

    assign io_SCL = SCL_oe ? 1'b0 : 1'bz;
    assign io_SDA = SDA_oe ? 1'b0 : 1'bz;

    assign SCL_in = io_SCL; //SCL_oe = 0
    assign SDA_in = io_SDA; //SDA_oe = 0
    
    assign o_RxByte = RxByte;
    assign o_Done = Cmd == CMD_NULL;
    assign o_GetAck = GetAck;

    assign clockStretchCond = (SCL_in == 1 || waitSCL_cnt == IIC_STRENTCH_MAX_CNT);
    assign iicSCLPreiodDiv2Cond = (cycle_cnt >= (IIC_SCL_PERIOD_MAX_CNT/2));
    assign iicSCLPreiodDiv1Cond = (cycle_cnt >= IIC_SCL_PERIOD_MAX_CNT);
    assign readCmd = Cmd == CMD_RDDATA;

    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            SCL_oe <= 0;
            SDA_oe <= 0;
            SetAck <= 0;
            GetAck <= 0;
            Cmd <= CMD_NULL;
            cycle_cnt <= 0;
            bit_cnt <= 0;
            CmdNext <= 0;
            waitSCL_cnt <= 0;
            RxByte <= 0;
        end else begin
            if (i_CmdValid && Cmd == CMD_NULL) begin
                Cmd <= i_Cmd;
                cycle_cnt <= 0;
                bit_cnt <= 0;
                CmdNext <= 0;
                waitSCL_cnt <= 0;
                SetAck <= i_SetAck;

                if (i_Cmd == CMD_RDDATA) begin
                    TxByte <= i_TxByte;
                end
            end
        end
    end

    always @(posedge i_SysClock) begin
        if (Cmd != CMD_NULL) begin
            cycle_cnt <= (cycle_cnt != IIC_SCL_PERIOD_MAX_CNT) ? cycle_cnt + 1 : cycle_cnt;
            waitSCL_cnt <= (waitSCL_cnt != IIC_STRENTCH_MAX_CNT) ? waitSCL_cnt + SCL_in : waitSCL_cnt;
        end

        if (Cmd == CMD_START) begin
           SDA_oe <= iicSCLPreiodDiv2Cond ? 1 : 0; //SDA H (OE = 0) -> L (OE = 1)
           SCL_oe <= iicSCLPreiodDiv1Cond ? 1 : 0; //SCL H (OE = 0) -> L (OE = 1)

           if (iicSCLPreiodDiv1Cond) begin
               if (clockStretchCond) begin
                   Cmd <= CMD_NULL;
               end
           end
        end else if (Cmd == CMD_WRDATA || Cmd == CMD_RDDATA) begin
            if (CmdNext == 0) begin
                if (iicSCLPreiodDiv2Cond) begin
                    if (bit_cnt < 8) begin
                        SDA_oe <= ((~readCmd) && (~TxByte[7])); //bit0-bit7
                    end else if (bit_cnt == 8) begin
                        SDA_oe <= (readCmd && (SetAck == 0)); //ack bit
                    end else begin
                        SDA_oe <= (~readCmd) || (readCmd && (SetAck == 0)) ; // next to stop or restart
                    end
                end

                SCL_oe <= iicSCLPreiodDiv1Cond ? 0 : 1; //SCL L (OE = 1) -> H (OE = 0)

                if (iicSCLPreiodDiv1Cond) begin
                    if (clockStretchCond) begin
                        CmdNext <= ~CmdNext;
                        GetAck <= (bit_cnt == 8) ? SDA_in : GetAck;
                        TxByte <= bit_cnt < 8 ? {TxByte[6:0],TxByte[7]} : TxByte;
                        RxByte <= (readCmd && bit_cnt < 8) ? {RxByte[6:0],SDA_in} : RxByte;
                        cycle_cnt <= 0;
                    end
                end
            end else begin            
                SCL_oe <= iicSCLPreiodDiv1Cond ? 1 : 0; //SCL H (OE = 0) -> L (OE = 1)
            
                if (iicSCLPreiodDiv1Cond) begin
                    if (bit_cnt < 8) begin
                        CmdNext <= ~CmdNext;
                    end else begin
                        Cmd <= CMD_NULL;
                    end

                    bit_cnt <= bit_cnt + 1;
                    CmdNext <= ~CmdNext;
                    cycle_cnt <= 0;
                end
            end
            
        end else if (Cmd == CMD_STOP) begin
            if (CmdNext == 0) begin
                SDA_oe <= iicSCLPreiodDiv2Cond ? 1 : SDA_oe; //SDA L (OE = old) -> L (OE = 1)
                SCL_oe <= iicSCLPreiodDiv1Cond ? 0 : 1; //SCL L (OE = 1) -> H (OE = 0)
                
                if (iicSCLPreiodDiv1Cond) begin
                    CmdNext <= ~CmdNext;
                end
            end else begin
                SDA_oe <= iicSCLPreiodDiv2Cond ? 0 : 1; //SDA L (OE = 1) -> H (OE = 0)
                SCL_oe <= 0; //SCL H (OE = 0) -> H (OE = 0)

                if (iicSCLPreiodDiv2Cond) begin
                    if (clockStretchCond) begin
                        Cmd <= CMD_NULL;
                    end
                end
            end
        end else if (Cmd == CMD_PRE_START) begin    
            SDA_oe <= iicSCLPreiodDiv2Cond ? 0 : 1; //SDA L (OE = 1) -> H (OE = 0)
            SCL_oe <= iicSCLPreiodDiv1Cond ? 0 : 1; //SCL L (OE = 1) -> H (OE = 0)
        
            if (iicSCLPreiodDiv1Cond) begin
                Cmd <= CMD_NULL;
            end
        end
    end

endmodule
`resetall
