module sync_gen(
    input wire reset,
    input wire clk,

    input [4:0] char_pixel_size,    // width/height of a character in pixels (-1)
    input [7:0] char_total,         // total characters per scanline/frame (-1)
    input [7:0] char_displayed,     // number characters displayed per row/col
    input [7:0] sync_pos,
    input [3:0] sync_width,
    input [4:0] adjust,             // fine adjustment in pixels

    output wire active,
    output wire sync
);
    reg [4:0] pixel_counter;
    reg [7:0] char_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_counter <= 0;
            char_counter <= 0;
        end else if (pixel_counter == char_pixel_size) begin
            pixel_counter <= 0;
            if (char_counter == char_total) begin
                char_counter <= 0;
            end else begin
                char_counter <= char_counter + 1'b1;
            end
        end else if (pixel_counter != 0 || adjust_counter == 0) begin
            pixel_counter <= pixel_counter + 1'b1;
        end
    end

    reg [4:0] adjust_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            adjust_counter <= 0;
        end else if (char_counter == char_total)  begin
            adjust_counter <= adjust;
        end else if (adjust_counter != 0) begin
            adjust_counter <= adjust_counter - 1'b1;
        end
    end

    localparam ACTIVE = 0,
               FRONT  = 1,
               SYNC   = 2,
               BACK   = 3,
               ADJUST = 4;

    reg [2:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state = ACTIVE;
        end else if (char_counter == char_displayed) begin
            state = FRONT;
        end else if (char_counter == sync_pos) begin
            state = SYNC;
        end else if (char_counter == sync_pos + sync_width) begin
            state = BACK;
        end else if (char_counter == 0) begin
            if (adjust_counter == 0) begin
                state = ACTIVE;
            end else begin
                state = ADJUST;
            end
        end
    end

    assign active = state == ACTIVE;
    assign sync   = state == SYNC;
endmodule

module video_gen(
    input reset,
    input pixel_clk,                // 16 MHz pixel clock

    input [7:0] h_char_total,       // Total characters per scanline (-1).
    input [7:0] h_char_displayed,   // Displayed characters per row
    input [7:0] h_sync_pos,         // Start of hsync pulse (in characters)
    input [3:0] h_sync_width,       // Width of hsync pulse (in characters), 0 = 16

    input [4:0] v_char_height,      // Character height in scanlines (-1)
    input [6:0] v_char_total,       // Total characters per frame (-1)
    input [6:0] v_char_displayed,   // Displayed characters per column
    input [6:0] v_sync_pos,         // Start of vsync pulse (in characters)
    input [3:0] v_sync_width,       // Width of vsync pulse (in characters), 0 = 16
    input [4:0] v_adjust,           // Fine vertical adjustment in scanlines

    output h_active,
    output h_sync,

    output v_active,
    output v_sync
);
    sync_gen h_sync_gen(
        .reset(reset),
        .clk(pixel_clk),
        .char_pixel_size(5'd7),
        .char_total(h_char_total),
        .char_displayed(h_char_displayed),
        .sync_pos(h_sync_pos),
        .sync_width(h_sync_width),
        .adjust(5'd0),
        .active(h_active),
        .sync(h_sync)
    );

    sync_gen v_sync_gen(
        .reset(reset),
        .clk(h_sync),
        .char_pixel_size(v_char_height),
        .char_total({ 1'b0, v_char_total }),
        .char_displayed({ 1'b0, v_char_displayed }),
        .sync_pos({ 1'b0, v_sync_pos }),
        .sync_width(v_sync_width),
        .adjust(v_adjust),
        .active(v_active),
        .sync(v_sync)
    );
endmodule

module video(
    input       reset,
    input       pixel_clk,
    output      video,
    output      h_sync,
    output      v_sync
);
    localparam R0_H_TOTAL           = 0,    // [7:0] Total displayed and non-displayed characters, minus one, per horizontal line.
                                            //       The frequency of HSYNC is thus determined by this register.
              
               R1_H_DISPLAYED       = 1,    // [7:0] Number of displayed characters per horizontal line.
              
               R2_H_SYNC_POS        = 2,    // [7:0] Position of the HSYNC on the horizontal line, in terms of the character location number on the line.
                                            //       The position of the HSYNC determines the left-to-right location of the displayed text on the video screen.
                                            //       In this way, the side margins are adjusted.

               R3_SYNC_WIDTH        = 3,    // [7:4] Width of VSYNC in scan lines
                                            // [3:0] Width of HSYNC in character clock times

               R4_V_TOTAL           = 4,    // [6:0] Total number of character rows in a frame, minus one. This register, along with R5,
                                            //       determines the overall frame rate, which should be close to the line frequency to
                                            //       ensure flicker-free appearance. If the frame time is adjusted to be longer than the
                                            //       period of the line frequency, then /RES may be used to provide absolute synchronism.

               R5_V_TOTAL_ADJUST    = 5,    // [4:0] Number of additional scan lines needed to complete an entire frame scan and is intended
                                            //       as a fine adjustment for the video frame time.

               R6_V_DISPLAYED       = 6,    // [6:0] Number of displayed character rows in each frame. In this way, the vertical size of the
                                            //       displayed text is determined.
            
               R7_V_SYNC_POS        = 7,    // [6:0] Selects the character row time at which the VSYNC pulse is desired to occur and, thus,
                                            //       is used to position the displayed text in the vertical direction.
            
               R9_SCAN_LINE         = 9;    // [4:0] Number of scan lines per character row, including spacing.

    reg [7:0] r [0:16];

    always @(posedge reset) begin
        // These non-standard CRTC values produce ~NTSC video.

        r[R0_H_TOTAL]           = 8'd63;
        r[R1_H_DISPLAYED]       = 8'd40;
        r[R2_H_SYNC_POS]        = 8'd48;
        r[R3_SYNC_WIDTH]        = 8'h15;
        r[R4_V_TOTAL]           = 7'd32;
        r[R5_V_TOTAL_ADJUST]    = 5'd00;
        r[R6_V_DISPLAYED]       = 7'd25;
        r[R7_V_SYNC_POS]        = 7'd28;
        r[8] = 8'h00;
        r[R9_SCAN_LINE]         = 5'd07;
        r[10] = 8'h00;
        r[11] = 8'h00;
        r[12] = 8'h10;
        r[13] = 8'h00;
        r[14] = 8'h00;
        r[15] = 8'h00;
        r[16] = 8'h00;
    end

    wire h_active;
    wire v_active;
    
    video_gen vg(
        .reset(reset),
        .pixel_clk(pixel_clk),

        .h_char_total(r[R0_H_TOTAL]),
        .h_char_displayed(r[R1_H_DISPLAYED]),
        .h_sync_pos(r[R2_H_SYNC_POS]),
        .h_sync_width(r[R3_SYNC_WIDTH][3:0]),

        .v_char_height(r[R9_SCAN_LINE][4:0]),
        .v_char_total(r[R4_V_TOTAL][6:0]),
        .v_char_displayed(r[R6_V_DISPLAYED][6:0]),
        .v_sync_pos(r[R7_V_SYNC_POS][6:0]),
        .v_sync_width(r[R3_SYNC_WIDTH][7:4]),
        .v_adjust(r[R5_V_TOTAL_ADJUST][4:0]),

        .h_sync(h_sync),
        .h_active(h_active),
        
        .v_sync(v_sync),
        .v_active(v_active)
    );
    
    assign video = h_active & v_active;
endmodule
