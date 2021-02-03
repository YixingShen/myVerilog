//20210126 UART Transmitter
// synthesis translate_off
`timescale 1 ns / 1 ps
// synthesis translate_on
`default_nettype none

module bt656_tx
    #(
    parameter SYS_CLOCK   = 50000000,
    parameter PIXEL_CLOCK = 12500000
    )(
    input wire i_ResetN,
    input wire i_SysClock,
    input wire i_TxValid,
    input wire i_Mode,
    input wire [3:0] i_FirstLine,
    input wire i_FirstField, //0: ODD; 1: EVEN
    output wire [7:0] o_Data,
    output wire o_PixelClock,
    output wire o_Vsignal,
    output wire o_Hsignal,
    output wire o_Fsignal
    );
    //F0
    //EAV V Blank  0xB6  SAV V Blank  0xAB
    //EAV V Active 0x9D  SAV V Active 0x80
    //F1
    //EAV V Blank  0xF1  SAV V Blank  0xEC
    //EAV V Active 0xDA  SAV V Active 0xC7
    
    //0xFF 0x00 0x00 EAV 0x80 0x10 0x80 0x10 ... 0xFF 0x00 0x00 SAV CB Y CR Y CB Y CR Y ...
    //EAV/SAV: D6 for F, D5 for V, D4 for H
 
    localparam F1_VBLK_EAV = 8'hB6;
    localparam F1_VBLK_SAV = 8'hAB;
    localparam F1_VACT_EAV = 8'h9D;
    localparam F1_VACT_SAV = 8'h9D;
    localparam F2_VBLK_EAV = 8'hF1;
    localparam F2_VBLK_SAV = 8'hEC;
    localparam F2_VACT_EAV = 8'hDA;
    localparam F2_VACT_SAV = 8'hC7;
    
    //EAV,SAV,H,V
    parameter s_VBLK_EAV     = 4'b1011; 
    parameter s_VBLK_EAV2SAV = 4'b0011;
    parameter s_VBLK_SAV     = 4'b0111;
    parameter s_VBLK_HACT    = 4'b0001;
    parameter s_VACT_EAV     = 4'b1010;
    parameter s_VACT_EAV2SAV = 4'b0010;
    parameter s_VACT_SAV     = 4'b0110;
    parameter s_VACT_HACT    = 4'b0000;

    parameter HACT_PIXELS   = 22; 
    parameter HBLK_PIXELS   = 16; 
    parameter VACT_LINES_F1 = 20; 
    parameter VBLK_LINES_F1 = 16;
    parameter VACT_LINES_F2 = 20; 
    parameter VBLK_LINES_F2 = 16;

    reg [$clog2(SYS_CLOCK / PIXEL_CLOCK):0] prescaler_count;
    reg [$clog2(HACT_PIXELS + HBLK_PIXELS):0] pixel_count;
    reg [$clog2(VACT_LINES_F1 + VBLK_LINES_F1):0] line_count;
    reg [7:0] frame_count;

    reg [4:0] status, next_status; //EAV,SAV,H(next_status[2]),V(next_status[1]),F(next_status[0])
    reg Vsignal;
    reg Hsignal;
    reg Fsignal;
    reg EAVsignal;
    reg SAVsignal;
    reg [31:0] Dout;
    reg [3:0] byte_count;
    reg Mode;
    reg handling;
    wire PixelClock;
    wire bitP3,bitP2,bitP1,bitP0,bitH,bitV,bitF,bitEAV,bitSAV;
    wire [7:0] EmbbedSync;
    
    assign o_Vsignal = Vsignal;
    assign o_Hsignal = Hsignal;
    assign o_Fsignal = Fsignal;
    assign o_Data = handling == 1 ? Dout[31:24] : 0;
    assign o_PixelClock = handling == 1 ? ~PixelClock : 0;
    assign PixelClock = prescaler_count[$clog2(SYS_CLOCK / PIXEL_CLOCK)];

    assign bitEAV = next_status[4];
    assign bitSAV = next_status[3];
    assign bitH = !bitSAV;
    assign bitV = next_status[1];
    assign bitF = next_status[0];
    assign bitP3 = bitV ^ bitH;
    assign bitP2 = bitF ^ bitH;
    assign bitP1 = bitF ^ bitV;
    assign bitP0 = (bitF ^ bitV) ^ bitH;
    assign EmbbedSync = {1'b1,bitF,bitV,bitH,bitP3,bitP2,bitP1,bitP0};
    
    always @(posedge PixelClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            status <= {s_VBLK_EAV, 1'b0};
            Mode <= 0;
        end else begin
            if (i_TxValid && handling == 0) begin
                status <= {status[4:1], i_FirstField};
                Mode <= i_Mode;
            end else begin
                status <= next_status;
            end
        end
    end

    always @(posedge PixelClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            byte_count <= 0;
            Dout <= 0;
        end else begin

            if (handling == 0) begin
                Dout <= 0;
            end else if (bitEAV == 1 || bitSAV == 1) begin
                Dout <= byte_count == 0 ? {24'hFF0000,EmbbedSync} : {Dout[23:0],Dout[31:24]};
            end else if (bitH == 1) begin
                Dout[31:24] <= byte_count == 0 ? 8'h80 : 8'h10;
            end else if (bitV == 1) begin
                Dout[31:24] <= 8'h00;
            end else
                Dout[31:24] <= 8'hAA;

            if (handling == 0) begin
                byte_count <= 0;
            end else if (bitEAV == 1 || bitSAV == 1) begin
                byte_count <= byte_count != 3 ? byte_count + 1 : 0;
            end else if (bitH == 1) begin
                byte_count <= byte_count == 0 ? 1 : 0;
            end else begin
                byte_count <= 0;
            end

            //EAV,SAV,H,V,F
            EAVsignal <= bitEAV;
            SAVsignal <= bitSAV;
            Hsignal <= next_status[2];
            Vsignal <= bitV;
            Fsignal <= bitF;
        end
    end

    always @(*) begin
        next_status[0] = frame_count[0];

        case (status[4:1])
            s_VBLK_EAV: begin
                if (pixel_count == 4)
                    next_status[4:1] = s_VBLK_EAV2SAV;
                else
                    next_status[4:1] = s_VBLK_EAV;
            end
            s_VBLK_EAV2SAV: begin
                if (pixel_count == (HBLK_PIXELS - 4))
                    next_status[4:1] = s_VBLK_SAV;
                else
                    next_status[4:1] = s_VBLK_EAV2SAV;
            end
            s_VBLK_SAV: begin
                 if (pixel_count == HBLK_PIXELS)
                    next_status[4:1] = s_VBLK_HACT;
            end
            s_VBLK_HACT: begin
                if (pixel_count == 0 && line_count == VBLK_LINES_F1)
                    next_status[4:1] = s_VACT_EAV;
                else if (pixel_count == 0)
                    next_status[4:1] = s_VBLK_EAV;
                else
                    next_status[4:1] = s_VBLK_HACT;
            end
            s_VACT_EAV: begin
                if (pixel_count == 4)
                    next_status[4:1] = s_VACT_EAV2SAV;
                else
                    next_status[4:1] = s_VACT_EAV;
            end
            s_VACT_EAV2SAV: begin
                if (pixel_count == (HBLK_PIXELS - 4))
                    next_status[4:1] = s_VACT_SAV;
                else
                    next_status[4:1] = s_VACT_EAV2SAV;
            end
            s_VACT_SAV: begin
                if (pixel_count == HBLK_PIXELS)
                    next_status[4:1] = s_VACT_HACT;
                else
                    next_status[4:1] = s_VACT_SAV;
            end
            s_VACT_HACT: begin
                if (pixel_count == 0 && line_count == 0) begin
                    next_status[4:1] = s_VBLK_EAV;
                end else if (pixel_count == 0) begin
                    next_status[4:1] = s_VACT_EAV;
                end else begin
                    next_status[4:1] = s_VACT_HACT;
                end
            end
            default: begin
                next_status[4:1] = s_VBLK_EAV;
            end
        endcase
    end
    
    always @(posedge i_SysClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            prescaler_count <= 0;
        end else begin
            prescaler_count <= prescaler_count + 1;
        end
    end

    always @(posedge PixelClock, negedge i_ResetN) begin
        if (!i_ResetN) begin
            pixel_count <= 0;
            line_count <= 0;
            handling <= 0;
            frame_count <= 0;
        end else begin
            if (i_TxValid && handling == 0) begin
                pixel_count <= 0;
                line_count <= i_FirstLine;
                handling <= 1;
                frame_count <= i_FirstField;
            end
            
            if (pixel_count == (HACT_PIXELS + HBLK_PIXELS - 1)) begin
                pixel_count <= 0;

                if (line_count == (VACT_LINES_F1 + VBLK_LINES_F1 - 1)) begin
                    line_count <= 0;
                    frame_count <= frame_count + 1;
                end else begin
                    line_count <= line_count + 1;
                end
            end else begin
                pixel_count <= handling == 1 ? pixel_count + 1 : 0;
            end
        end
    end
    
endmodule
`resetall
