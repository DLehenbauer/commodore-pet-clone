module sync_gen(
    input wire reset,
    input wire clk,

    input [4:0] char_pixel_size,    // Width/height of one character in pixels (-1)
    input [7:0] char_total,         // Total characters per scanline/frame (-1)
    input [7:0] char_displayed,     // Number characters displayed per row/col
    input [7:0] sync_pos,           // Character offset at which sync pulse begins
    input [3:0] sync_width,         // Width of sync pulse in characters
    input [4:0] adjust,             // Fine adjustment in pixels

    output wire first,              // First pixel/scanline of row/col
    output wire last,               // Last pixel/scanline of row/col
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

    assign first = pixel_counter == 0;
    assign last = pixel_counter == char_pixel_size;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_counter <= 0;
            char_counter <= 0;
            state <= ACTIVE;
        end else if (last) begin
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
    input col_start,
    input col_end,                  // Character clock (40 col = 1 MHz)
    input h_active,
    input h_sync,
    input v_active,
    input v_sync,
    input row_start,
    input row_end,

    output     [11:0] addr_out,     // 2KB video ram ($000-7FF) or 2KB character rom ($800-FFF)
    input       [7:0] data_in,
    input             video_ram_strobe,
    input             video_rom_strobe,

    output video_out
);
    reg [10:0] row_addr;

    wire active = h_active & v_active;
    wire next_line = row_end & active;

    always @(posedge next_line or posedge v_sync or posedge reset) begin
        if (reset) begin
            row_addr <= 0;
        end else if (v_sync) begin
            row_addr <= 0;
        end else begin
            row_addr <= row_addr + 11'd40;
        end
    end

    reg [10:0] char_addr;
    
    reg [7:0] pixels_out;
    reg reverse_video;

    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            pixels_out <= 8'h0;
        end else begin
            if (col_end) begin
                pixels_out <= next_pixels_out;
                reverse_video <= next_char_out[7];
            end else begin
                pixels_out[7:0] <= { pixels_out[6:0], 1'b0 };
            end
        end
    end    
    
    assign video_out = (pixels_out[7] ^ reverse_video) & active;

    reg [4:0] char_y_counter;

    reg prev_row_end;
    reg next_row;

    always @(posedge pixel_clk) begin
        prev_row_end <= row_end & h_active;
        next_row <= prev_row_end & !(row_end & h_active);
    end

    always @(negedge h_active or posedge next_row or posedge reset) begin
        if (reset) begin
            char_y_counter <= 0;
        end else if (next_row) begin
            char_y_counter <= 0;
        end else begin
            char_y_counter <= char_y_counter + 1'b1;
        end
    end

    reg [7:0] next_char_out;

    always @(posedge video_ram_strobe or posedge reset) begin
        if (reset) begin
            char_addr <= 0;
        end else if (video_ram_strobe) begin
            char_addr <= active
                ? char_addr + 1'b1
                : row_addr;
        end
    end

    assign addr_out = video_rom_strobe
        ? { 2'b10, next_char_out[6:0], char_y_counter[2:0] }
        : { 1'b0, char_addr };

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
    wire col_start;
    wire col_end;

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
        .first(col_start),
        .last(col_end)
    );

    wire row_start;
    wire row_end;

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
        .first(row_start),
        .last(row_end)
    );

    dot_gen dot_gen(
        .reset(reset),
        .pixel_clk(pixel_clk),
        .col_start(col_start),
        .col_end(col_end),
        .h_sync(h_sync),
        .h_active(h_active),
        .v_sync(v_sync),
        .v_active(v_active),
        .row_start(row_start),
        .row_end(row_end),
        .addr_out(addr_out),
        .data_in(data_in),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),
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
    `include "crtc.vh"

    reg [7:0] r [0:16];

    always @(posedge reset) begin
        // These non-standard CRTC values produce ~NTSC video.

        r[R0_H_TOTAL]           = 8'd63;
        r[R1_H_DISPLAYED]       = 8'd40;
        r[R2_H_SYNC_POS]        = 8'd48;
        r[R3_SYNC_WIDTH]        = 8'h15;
        r[R4_V_TOTAL]           = 7'd32;
        r[R5_V_LINE_ADJUST]     = 5'd00;
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
        .v_adjust(r[R5_V_LINE_ADJUST][4:0]),

        .h_sync(h_sync),
        .h_active(h_active),
        
        .v_sync(v_sync),
        .v_active(v_active),
        
        .video_out(video_out)
    );
endmodule