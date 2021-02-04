//20210202 BT656
// synthesis translate_off
`timescale 1 ns / 1 ps
// synthesis translate_on
`default_nettype none

module bt656_tx
    #(
    parameter SYS_CLOCK         = 50000000,
    parameter PIXEL_CLOCK       = 12500000,
    parameter HACT_PIXELS       = 720*2,
    parameter HBLK_PIXELS       = (19+62+57)*2, 
    parameter VACT_LINES_F1     = 240, 
    parameter VBLK_LINES_F1_TOP = 18,
    parameter VBLK_LINES_F1_BOT = 4,
    parameter VACT_LINES_F2     = 240, 
    parameter VBLK_LINES_F2_TOP = 18,
    parameter VBLK_LINES_F2_BOT = 5
    )(
    input wire i_ResetN,
    input wire i_SysClock,
    input wire i_TxValid,
    input wire i_InterlaceMode,
    input wire i_FirstField,
    input wire [15:0] i_FirstLine,
    output wire [7:0] o_Data,
    output wire o_PixelClock,
    output wire o_Vsignal,
    output wire o_Hsignal,
    output wire o_Fsignal
    );

    //[4:1] for EAV,SAV,H,V; [0] for F
    localparam s_MSB4BIT_VBLK_EAV     = 4'b1011; //B
    localparam s_MSB4BIT_VBLK_EAV2SAV = 4'b0011; //3
    localparam s_MSB4BIT_VBLK_SAV     = 4'b0111; //7
    localparam s_MSB4BIT_VBLK_HACT    = 4'b0001; //1
    localparam s_MSB4BIT_VACT_EAV     = 4'b1010; //A
    localparam s_MSB4BIT_VACT_EAV2SAV = 4'b0010; //2
    localparam s_MSB4BIT_VACT_SAV     = 4'b0110; //6
    localparam s_MSB4BIT_VACT_HACT    = 4'b0000; //0
    localparam s_LSB1BIT_F1           = 1'b0;
    localparam s_LSB1BIT_F2           = 1'b1;
    
    reg [4:0] status, next_status; //[4:1] for EAV,SAV,H,V; [0] for F
    reg [$clog2(SYS_CLOCK / PIXEL_CLOCK) - 1:0] prescaler_count;
    reg [$clog2(HACT_PIXELS + HBLK_PIXELS):0] pixel_count;
    wire [$clog2(HACT_PIXELS + HBLK_PIXELS):0] pixel_count_max;
    reg [$clog2(VACT_LINES_F2 + VBLK_LINES_F2_TOP + VBLK_LINES_F2_BOT):0] line_count;
    wire [$clog2(VACT_LINES_F2 + VBLK_LINES_F2_TOP + VBLK_LINES_F2_BOT):0] line_count_max;

    reg Vsignal;
    reg Hsignal;
    reg Fsignal;
    reg EAVsignal;
    reg SAVsignal;
    reg [31:0] Dout;
    reg [3:0] byte_count;
    reg InterlaceMode;
    reg displaying;
    reg field_id;
    wire PixelClock;
    wire [7:0] EmbbedSync;
    wire bitP3,bitP2,bitP1,bitP0;
    wire VBLK_HACT_to_VACT_EAV_Cond;
    wire VACT_HACT_to_VBLK_EAV_Cond;
    wire DISPLAYER_OUT_Cond;
    wire TRIG_DISPLAYER_Cond;

    assign DISPLAYER_OUT_Cond = (displaying == 1 && i_ResetN);
    assign TRIG_DISPLAYER_Cond = (i_TxValid && displaying == 0);
    assign o_Vsignal = DISPLAYER_OUT_Cond ? Vsignal : 1;
    assign o_Hsignal = DISPLAYER_OUT_Cond ? Hsignal : 1;
    assign o_Fsignal = DISPLAYER_OUT_Cond ? Fsignal : 0;
    assign o_Data = DISPLAYER_OUT_Cond ? Dout[31:24] : 0;
    assign o_PixelClock = DISPLAYER_OUT_Cond ? ~PixelClock : 0;
    assign PixelClock = prescaler_count[$clog2(SYS_CLOCK / PIXEL_CLOCK) - 1];

    always @(posedge i_SysClock, negedge i_ResetN) begin : FreqDivisor
        if (!i_ResetN) begin
            prescaler_count <= 0;
        end else begin
            prescaler_count <= prescaler_count + 1;
        end
    end

    assign pixel_count_max = (HACT_PIXELS + HBLK_PIXELS - 1);

    always @(posedge PixelClock, negedge i_ResetN) begin : PixelCounter
        if (!i_ResetN) begin
            pixel_count <= 0;
        end else begin
            if (TRIG_DISPLAYER_Cond) begin
                pixel_count <= 0;
            end else if (displaying == 1) begin
                if (pixel_count == pixel_count_max) begin
                    pixel_count <= 0;
                end else begin
                    pixel_count <= pixel_count + 1;
                end
            end
        end
    end

    assign line_count_max = next_status[0] == s_LSB1BIT_F1 ? (VACT_LINES_F1 + VBLK_LINES_F1_TOP + VBLK_LINES_F1_BOT - 1) : (VACT_LINES_F2 + VBLK_LINES_F2_TOP + VBLK_LINES_F2_BOT - 1);

    always @(posedge PixelClock, negedge i_ResetN) begin : LineCounter
        if (!i_ResetN) begin
            line_count <= 0;
            field_id <= s_LSB1BIT_F1;
        end else begin
            if (TRIG_DISPLAYER_Cond) begin
                line_count <= i_FirstLine;
                field_id <= i_FirstField;
            end else if (displaying == 1) begin
                if (pixel_count == pixel_count_max) begin
                    if (line_count == line_count_max) begin
                        line_count <= 0;
                        field_id <= ~field_id;
                    end else begin
                        line_count <= line_count + 1;
                    end
                end
            end
        end
    end

    always @(posedge PixelClock, negedge i_ResetN) begin : UpdateStatusMachine
        if (!i_ResetN) begin
            status <= {s_MSB4BIT_VBLK_EAV, s_LSB1BIT_F1};
            displaying <= 0;
        end else if (TRIG_DISPLAYER_Cond) begin
            displaying <= 1;
        end else if (displaying == 1) begin
            status <= next_status;
        end
    end
    
    always @(posedge PixelClock, negedge i_ResetN) begin : InterlaceModeSelector
        if (!i_ResetN) begin
            InterlaceMode <= 0;
        end else if (TRIG_DISPLAYER_Cond) begin
            InterlaceMode <= i_InterlaceMode;
        end
    end

    always @(posedge PixelClock) begin : SyncGen
        EAVsignal <= next_status[4];
        SAVsignal <= next_status[3];
        Hsignal <= next_status[2];
        Vsignal <= next_status[1];
        Fsignal <= next_status[0];
    end

    assign bitP3 = next_status[1] ^ (~next_status[3]);
    assign bitP2 = next_status[0] ^ (~next_status[3]);
    assign bitP1 = next_status[0] ^ next_status[1];
    assign bitP0 = (next_status[0] ^ next_status[1]) ^ (~next_status[3]);
    assign EmbbedSync = {1'b1,next_status[0],next_status[1],(~next_status[3]),bitP3,bitP2,bitP1,bitP0};
    
    always @(posedge PixelClock, negedge i_ResetN) begin : DataOut
        if (!i_ResetN) begin
            byte_count <= 0;
            Dout <= 0;
        end else begin
            if (displaying == 0) begin
                Dout <= 0;
            end else if (next_status[4] || next_status[3]) begin
                Dout <= byte_count == 0 ? {24'hFF0000,EmbbedSync} : {Dout[23:0],Dout[31:24]};
            end else if (next_status[2]) begin
                Dout <= byte_count == 0 ? 32'h80108010 : {Dout[23:0],Dout[31:24]};
            end else begin
                Dout <= byte_count == 0 ? {8'h25,8'hAA,8'h5A,8'h55} : {Dout[23:0],Dout[31:24]}; //Cb,Y,Cr,Y
            end

            if (displaying == 0) begin
                byte_count <= 0;
            end else begin
                byte_count <= byte_count != 3 ? byte_count + 1 : 0;
            end
        end
    end

    assign VBLK_HACT_to_VACT_EAV_Cond = next_status[0] == s_LSB1BIT_F1 ? (line_count == VBLK_LINES_F1_TOP) : (line_count == VBLK_LINES_F2_TOP);
    assign VACT_HACT_to_VBLK_EAV_Cond = next_status[0] == s_LSB1BIT_F1 ? (line_count == (VACT_LINES_F1 + VBLK_LINES_F1_TOP)) : (line_count == (VACT_LINES_F2 + VBLK_LINES_F2_TOP));

    always @(*) begin : NextStatusMachine
        next_status[0] = InterlaceMode == 0 ? s_LSB1BIT_F1 : field_id;

        case (status[4:1])
            s_MSB4BIT_VBLK_EAV: begin
                if (pixel_count == 4)
                    next_status[4:1] = s_MSB4BIT_VBLK_EAV2SAV;
                else
                    next_status[4:1] = s_MSB4BIT_VBLK_EAV;
            end
            s_MSB4BIT_VBLK_EAV2SAV: begin
                if (pixel_count == (HBLK_PIXELS - 4))
                    next_status[4:1] = s_MSB4BIT_VBLK_SAV;
                else
                    next_status[4:1] = s_MSB4BIT_VBLK_EAV2SAV;
            end
            s_MSB4BIT_VBLK_SAV: begin
                 if (pixel_count == HBLK_PIXELS)
                    next_status[4:1] = s_MSB4BIT_VBLK_HACT;
                 else
                    next_status[4:1] = s_MSB4BIT_VBLK_SAV;
            end
            s_MSB4BIT_VBLK_HACT: begin
                if (pixel_count == 0 && VBLK_HACT_to_VACT_EAV_Cond)
                    next_status[4:1] = s_MSB4BIT_VACT_EAV;
                else if (pixel_count == 0)
                    next_status[4:1] = s_MSB4BIT_VBLK_EAV;
                else
                    next_status[4:1] = s_MSB4BIT_VBLK_HACT;
            end
            s_MSB4BIT_VACT_EAV: begin
                if (pixel_count == 4)
                    next_status[4:1] = s_MSB4BIT_VACT_EAV2SAV;
                else
                    next_status[4:1] = s_MSB4BIT_VACT_EAV;
            end
            s_MSB4BIT_VACT_EAV2SAV: begin
                if (pixel_count == (HBLK_PIXELS - 4))
                    next_status[4:1] = s_MSB4BIT_VACT_SAV;
                else
                    next_status[4:1] = s_MSB4BIT_VACT_EAV2SAV;
            end
            s_MSB4BIT_VACT_SAV: begin
                if (pixel_count == HBLK_PIXELS)
                    next_status[4:1] = s_MSB4BIT_VACT_HACT;
                else
                    next_status[4:1] = s_MSB4BIT_VACT_SAV;
            end
            s_MSB4BIT_VACT_HACT: begin
                if (pixel_count == 0 && (line_count == 0 || VACT_HACT_to_VBLK_EAV_Cond)) begin
                    next_status[4:1] = s_MSB4BIT_VBLK_EAV;
                end else if (pixel_count == 0) begin
                    next_status[4:1] = s_MSB4BIT_VACT_EAV;
                end else begin
                    next_status[4:1] = s_MSB4BIT_VACT_HACT;
                end
            end
            default: begin
                next_status[4:1] = s_MSB4BIT_VBLK_EAV;
            end
        endcase
    end
    
endmodule
`resetall
