module sync_gen(
    input wire reset,
    input wire clk,

    input [4:0] char_pixel_size,    // Width/height of one character in pixels (-1)
    input [7:0] char_total,         // Total characters per scanline/frame (-1)
    input [7:0] char_displayed,     // Number characters displayed per row/col
    input [7:0] sync_pos,           // Character offset at which sync pulse begins
    input [3:0] sync_width,         // Width of sync pulse in characters
    input [4:0] adjust,             // Fine adjustment in pixels

    output wire next,               // Start of next row/col
    output wire active,             // Within the visible pertion of the display
    output wire sync                // Produced sync pulse
);
    reg [4:0] pixel_counter;        // X/Y pixel position within current character
    reg [7:0] char_counter;         // Current character (row/col)

    localparam ACTIVE = 0,          // Within visible portion of display
               FRONT  = 1,          // Blank prior to sync pulse
               SYNC   = 2,          // Sync pulse high
               BACK   = 3,          // Blank following sync pulse
               ADJUST = 4;          // Fine adjustment

    reg [2:0] state, next_state;

    // Indicates we've reached the end of the current character / text line
    assign next = pixel_counter == char_pixel_size;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_counter <= 0;
            char_counter <= 0;
            state <= ACTIVE;
        end else if (next) begin
            pixel_counter <= 0;
            if (char_counter == char_total) begin
                char_counter <= 0;
                state <= ACTIVE;
            end else begin
                char_counter <= next_char;
                state <= next_state;
            end
        end else begin
            pixel_counter <= pixel_counter + 1'b1;
        end
    end

    wire [7:0] next_char = char_counter + 1'b1;

    always @(*) begin
        if (next_char == sync_pos + sync_width) next_state = BACK;
        else if (next_char == sync_pos) next_state = SYNC;
        else if (next_char == char_displayed) next_state = FRONT;
        else next_state = state;
    end

    assign active = state == ACTIVE;
    assign sync   = state == SYNC;
endmodule

module dot_gen(
    input reset,
    input pixel_clk,                // Pixel clock (40 col = 8 MHz)
    input char_clk,                 // Character clock (40 col = 1 MHz)
    input h_sync,
    input v_sync,
    input line_clk,
    input active,

    output reg [11:0] addr_out = 0, // 2KB video ram ($000-7FF) or 2KB character rom ($800-FFF)
    input       [7:0] data_in,
    input             video_ram_strobe,
    input             video_rom_strobe,

    output video_out
);
    reg [10:0] video_row_addr;

    always @(posedge line_clk or posedge v_sync or posedge reset) begin
        if (reset) begin
            video_row_addr <= 0;
        end else if (v_sync) begin
            video_row_addr <= 0;
        end else begin
            video_row_addr <= video_row_addr + 11'd40;
        end
    end

    reg [10:0] video_addr;
    
    always @(posedge char_clk or posedge h_sync or posedge reset) begin
        if (reset) begin
            video_addr <= 0;
        end else if (h_sync) begin
            video_addr <= video_row_addr;
        end else begin
            if (active) begin
                video_addr <= video_addr + 1'b1;
            end
        end
    end

    reg [7:0] pixels_out;

    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            pixels_out <= 8'h0;
        end else begin
            if (char_clk) begin
                pixels_out <= next_pixels_out;
            end else begin
                pixels_out[7:0] <= { pixels_out[6:0], 1'b0 };
            end
        end
    end
    
    
    assign video_out = active & pixels_out[7];

    reg [4:0] char_y_counter;

    always @(posedge h_sync or posedge line_clk or posedge reset) begin
        if (reset | line_clk) begin
            char_y_counter <= 0;
        end else begin
            char_y_counter = char_y_counter + 1'b1;
        end
    end

    reg [7:0] next_char_out;

    always @(posedge video_ram_strobe or posedge video_rom_strobe or posedge reset) begin
        if (reset) begin
            addr_out <= 0;
        end else if (video_ram_strobe) begin
            addr_out <= { 1'b0, video_addr };
        end else begin       
            addr_out <= { 1'b1, next_char_out, char_y_counter[2:0] };
        end
    end

    always @(negedge video_ram_strobe) begin
        next_char_out <= data_in;
    end

    reg [7:0] next_pixels_out;

    always @(negedge video_rom_strobe) begin
        next_pixels_out <= data_in;
    end
endmodule

module video_gen(
    input reset,
    input pixel_clk,                // Pixel clock (40 col = 8 MHz)
    
    output [11:0] addr_out,
    input  [7:0]  data_in,
    input         video_ram_strobe,
    input         video_rom_strobe,

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
    output v_sync,

    output video_out
);
    wire char_clk;                  // Character clock (40 col = 1 MHz)

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
        .sync(h_sync),
        .next(char_clk)
    );

    wire line_clk;

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
        .sync(v_sync),
        .next(line_clk)
    );

    dot_gen dot_gen(
        .reset(reset),
        .pixel_clk(pixel_clk),
        .char_clk(char_clk),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .line_clk(line_clk),
        .addr_out(addr_out),
        .data_in(data_in),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),
        .active(h_active & v_active),
        .video_out(video_out)
    );
endmodule

module video(
    input         reset,
    input         pixel_clk,
    
    output [11:0] addr_out,
    input  [7:0]  data_in,
    input         video_ram_strobe,
    input         video_rom_strobe,
    
    output        video_out,
    output        h_sync,
    output        v_sync
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
        
        .addr_out(addr_out),
        .data_in(data_in),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),

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
        .v_active(v_active),
        
        .video_out(video_out)
    );
endmodule
