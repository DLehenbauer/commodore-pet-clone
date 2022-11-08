module h_sync_gen(
    input logic reset_i,
    input logic cclk_i,

    input logic [4:0] char_pixel_size_i,    // Width/height of one character in pixels (-1)
    input logic [7:0] char_total_i,         // Total characters per scanline/frame (-1)
    input logic [7:0] char_displayed_i,     // Number characters displayed per row/col
    input logic [7:0] sync_start_i,         // Character offset at which sync pulse begins
    input logic [3:0] sync_width_i,         // Width of sync pulse in characters
    input logic [4:0] adjust_i,             // Fine adjustment in pixels

    output logic active_o,                  // Within the visible pertion of the display
    output logic sync_o                     // Produced sync pulse
);
    localparam ACTIVE = 0,          // Within visible portion of display
               FRONT  = 1,          // Blank prior to sync pulse
               SYNC   = 2,          // Sync pulse high
               BACK   = 3,          // Blank following sync pulse
               ADJUST = 4;          // Fine adjustment

    logic [2:0] state, next_state;
    logic [7:0] char_counter;       // Current character (row/col)

    always_ff @(posedge cclk_i or posedge reset_i) begin
        if (reset_i) begin
            char_counter <= 0;
            state <= ACTIVE;
        end else begin
            if (char_counter == char_total_i) begin
                char_counter <= 0;
                state <= ACTIVE;
            end else begin
                char_counter <= next_char;
                state <= next_state;
            end
        end
    end

    logic [7:0] next_char;
    assign next_char = char_counter + 1'b1;

    always_comb begin
        if (next_char == sync_start_i + sync_width_i) next_state = BACK;
        else if (next_char == sync_start_i) next_state = SYNC;
        else if (next_char == char_displayed_i) next_state = FRONT;
        else next_state = state;
    end

    assign active_o = state == ACTIVE;
    assign sync_o   = state == SYNC;
endmodule


module sync_gen(
    input logic reset_i,
    input logic clk_i,

    input logic [4:0] char_pixel_size_i,    // Width/height of one character in pixels (-1)
    input logic [7:0] char_total_i,         // Total characters per scanline/frame (-1)
    input logic [7:0] char_displayed_i,     // Number characters displayed per row/col
    input logic [7:0] sync_start_i,         // Character offset at which sync pulse begins
    input logic [3:0] sync_width_i,         // Width of sync pulse in characters
    input logic [4:0] adjust_i,             // Fine adjustment in pixels

    output logic last_o,                    // Last pixel/scanline of row/col
    output logic active_o,                  // Within the visible pertion of the display
    output logic sync_o                     // Produced sync pulse
);
    localparam ACTIVE = 0,          // Within visible portion of display
               FRONT  = 1,          // Blank prior to sync pulse
               SYNC   = 2,          // Sync pulse high
               BACK   = 3,          // Blank following sync pulse
               ADJUST = 4;          // Fine adjustment

    logic [2:0] state, next_state;

    logic [4:0] pixel_ctr_d, pixel_ctr_q;
    assign last_o = pixel_ctr_q == char_pixel_size_i;

    always_comb begin
        if (last_o) pixel_ctr_d = 0;
        else pixel_ctr_d = pixel_ctr_q + 1'b1;
    end
    
    always_ff @(posedge clk_i or posedge reset_i) begin
        if (reset_i) pixel_ctr_q <= 0;
        else pixel_ctr_q <= pixel_ctr_d;
    end

    logic [7:0] char_counter;       // Current character (row/col)

    always_ff @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            char_counter <= 0;
            state <= ACTIVE;
        end else if (last_o) begin
            if (char_counter == char_total_i) begin
                char_counter <= 0;
                state <= ACTIVE;
            end else begin
                char_counter <= next_char;
                state <= next_state;
            end
        end
    end

    logic [7:0] next_char;
    assign next_char = char_counter + 1'b1;

    always_comb begin
        if (next_char == sync_start_i + sync_width_i) next_state = BACK;
        else if (next_char == sync_start_i) next_state = SYNC;
        else if (next_char == char_displayed_i) next_state = FRONT;
        else next_state = state;
    end

    assign active_o = state == ACTIVE;
    assign sync_o   = state == SYNC;
endmodule

module dot_gen(
    input logic reset_i,
    input logic pixel_clk_i,                // Pixel clock (40 col = 8 MHz)
    input logic video_ram_clk_i,
    input logic video_rom_clk_i,

    input logic col_end_i,
    input logic h_active_i,
    input logic h_sync_i,
    
    input logic v_active_i,
    input logic v_sync_i,
    input logic row_end_i,

    output logic [11:0] bus_addr_o,     // 2KB video ram ($000-7FF) or 2KB character rom ($800-FFF)
    input  logic  [7:0] bus_data_i,

    output logic video_o
);
    logic [10:0] row_addr;

    logic active;
    assign active = h_active_i & v_active_i;
    
    logic next_line;
    assign next_line = row_end_i & active;

    always_ff @(posedge next_line or posedge v_sync_i or posedge reset_i) begin
        if (reset_i) begin
            row_addr <= 0;
        end else if (v_sync_i) begin
            row_addr <= 0;
        end else begin
            row_addr <= row_addr + 11'd40;
        end
    end

    logic [10:0] char_addr;
    
    logic [7:0] pixels_out;
    logic reverse_video;

    always_ff @(posedge pixel_clk_i or posedge reset_i) begin
        if (reset_i) begin
            pixels_out <= 8'h0;
        end else begin
            if (col_end_i) begin
                pixels_out <= next_pixels_out;
                reverse_video <= next_char_out[7];
            end else begin
                pixels_out[7:0] <= { pixels_out[6:0], 1'b0 };
            end
        end
    end    
    
    assign video_o = (pixels_out[7] ^ reverse_video) & active;

    logic [4:0] char_y_counter;

    logic prev_row_end;
    logic next_row;

    always_ff @(posedge pixel_clk_i) begin
        prev_row_end <= row_end_i & h_active_i;
        next_row <= prev_row_end & !(row_end_i & h_active_i);
    end

    always_ff @(negedge h_active_i or posedge next_row or posedge reset_i) begin
        if (reset_i) begin
            char_y_counter <= 0;
        end else if (next_row) begin
            char_y_counter <= 0;
        end else begin
            char_y_counter <= char_y_counter + 1'b1;
        end
    end

    logic [7:0] next_char_out;

    always_ff @(posedge video_ram_clk_i or posedge reset_i) begin
        if (reset_i) begin
            char_addr <= 0;
        end else if (video_ram_clk_i) begin
            char_addr <= active
                ? char_addr + 1'b1
                : row_addr;
        end
    end

    assign bus_addr_o = video_rom_clk_i
        ? { 2'b10, next_char_out[6:0], char_y_counter[2:0] }
        : { 1'b0, char_addr };

    always_ff @(negedge video_ram_clk_i) begin
        next_char_out <= bus_data_i;
    end

    logic [7:0] next_pixels_out;

    always_ff @(negedge video_rom_clk_i) begin
        next_pixels_out <= bus_data_i;
    end
endmodule

module video_gen(
    input logic reset_i,
    input logic pixel_clk_i,              // Pixel clock (40 col = 8 MHz)
    input logic cclk_i,
    
    output logic [11:0] bus_addr_o,
    input  logic [7:0]  bus_data_i,
    input  logic video_ram_clk_i,
    input  logic video_rom_clk_i,

    input logic [7:0] h_char_total_i,     // Total characters per scanline (-1).
    input logic [7:0] h_char_displayed_i, // Displayed characters per row
    input logic [7:0] h_sync_start_i,     // Start of hsync pulse (in characters)
    input logic [3:0] h_sync_width_i,     // Width of hsync pulse (in characters), 0 = 16

    input logic [4:0] v_char_height_i,    // Character height in scanlines (-1)
    input logic [6:0] v_char_total_i,     // Total characters per frame (-1)
    input logic [6:0] v_char_displayed_i, // Displayed characters per column
    input logic [6:0] v_sync_start_i,     // Start of vsync pulse (in characters)
    input logic [3:0] v_sync_width_i,     // Width of vsync pulse (in characters), 0 = 16
    input logic [4:0] v_adjust_i,         // Fi vertical adjustment in scanlines

    input logic [13:0] display_start_i,

    output logic h_active_o,
    output logic h_sync_o,

    output logic v_active_o,
    output logic v_sync_o,

    output logic video_o
);
    logic [4:0] pixel_ctr_d, pixel_ctr_q;

    logic cclk;
    assign cclk = pixel_ctr_q == 5'd7;

    always_comb begin
        if (cclk) pixel_ctr_d = 0;
        else pixel_ctr_d = pixel_ctr_q + 1'b1;
    end
    
    always_ff @(posedge pixel_clk_i or posedge reset_i) begin
        if (reset_i) pixel_ctr_q <= 0;
        else pixel_ctr_q <= pixel_ctr_d;
    end

    h_sync_gen h_sync_gen(
        .reset_i(reset_i),
        .cclk_i(cclk),
        .char_pixel_size_i(5'd7),
        .char_total_i(h_char_total_i),
        .char_displayed_i(h_char_displayed_i),
        .sync_start_i(h_sync_start_i),
        .sync_width_i(h_sync_width_i),
        .adjust_i(5'd0),
        .active_o(h_active_o),
        .sync_o(h_sync_o)
    );

    logic row_end;

    sync_gen v_sync_gen(
        .reset_i(reset_i),
        .clk_i(h_sync_o),
        .char_pixel_size_i(v_char_height_i),
        .char_total_i({ 1'b0, v_char_total_i }),
        .char_displayed_i({ 1'b0, v_char_displayed_i }),
        .sync_start_i({ 1'b0, v_sync_start_i }),
        .sync_width_i(v_sync_width_i),
        .adjust_i(v_adjust_i),
        .active_o(v_active_o),
        .sync_o(v_sync_o),
        .last_o(row_end)
    );

    dot_gen dot_gen(
        .reset_i(reset_i),
        .pixel_clk_i(pixel_clk_i),
        .col_end_i(cclk),
        .h_sync_i(h_sync_o),
        .h_active_i(h_active_o),
        .v_sync_i(v_sync_o),
        .v_active_i(v_active_o),
        .row_end_i(row_end),
        .bus_addr_o(bus_addr_o),
        .bus_data_i(bus_data_i),
        .video_ram_clk_i(video_ram_clk_i),
        .video_rom_clk_i(video_rom_clk_i),
        .video_o(video_o)
    );
endmodule

module video(
    input  logic        reset_i,
    input  logic        clk8_i,         // 40 col = 8 MHz pixel clock
    input  logic        cclk_i,         // Character clock always 1 MHz
    
    output logic [11:0] bus_addr_o,
    input  logic [7:0]  bus_data_i,
    input  logic        video_ram_clk_i,
    input  logic        video_rom_clk_i,
    
    output logic        video_o,
    output logic        h_sync_o,
    output logic        v_sync_o
);
    `include "crtc.vh"

    logic [7:0] r [0:16];

    always_ff @(posedge reset_i) begin
        // These non-standard CRTC values produce ~NTSC video.

        r[R0_H_TOTAL]           <= 8'd63;
        r[R1_H_DISPLAYED]       <= 8'd40;
        r[R2_H_SYNC_POS]        <= 8'd48;
        r[R3_SYNC_WIDTH]        <= 8'h15;
        r[R4_V_TOTAL]           <= 7'd32;
        r[R5_V_LINE_ADJUST]     <= 5'd00;
        r[R6_V_DISPLAYED]       <= 7'd25;
        r[R7_V_SYNC_POS]        <= 7'd28;
        r[8]                    <= 8'h00;
        r[R9_SCAN_LINE]         <= 5'd07;
        r[10]                   <= 8'h00;
        r[11]                   <= 8'h00;
        r[R12_DISPLAY_START_HI] <= 8'h10;
        r[R13_DISPLAY_START_LO] <= 8'h00;
        r[14]                   <= 8'h00;
        r[15]                   <= 8'h00;
        r[16]                   <= 8'h00;
    end

    logic h_active;
    logic v_active;
    
    logic pixel_clk;
    assign pixel_clk = clk8_i;

    video_gen vg(
        .reset_i(reset_i),
        .pixel_clk_i(pixel_clk),
        .cclk_i(cclk_i),
        
        .bus_addr_o(bus_addr_o),
        .bus_data_i(bus_data_i),
        .video_ram_clk_i(video_ram_clk_i),
        .video_rom_clk_i(video_rom_clk_i),

        .h_char_total_i(r[R0_H_TOTAL]),
        .h_char_displayed_i(r[R1_H_DISPLAYED]),
        .h_sync_start_i(r[R2_H_SYNC_POS]),
        .h_sync_width_i(r[R3_SYNC_WIDTH][3:0]),

        .v_char_height_i(r[R9_SCAN_LINE][4:0]),
        .v_char_total_i(r[R4_V_TOTAL][6:0]),
        .v_char_displayed_i(r[R6_V_DISPLAYED][6:0]),
        .v_sync_start_i(r[R7_V_SYNC_POS][6:0]),
        .v_sync_width_i(r[R3_SYNC_WIDTH][7:4]),
        .v_adjust_i(r[R5_V_LINE_ADJUST][4:0]),

        .display_start_i({ r[R12_DISPLAY_START_HI][5:0], r[R13_DISPLAY_START_LO] }),

        .h_sync_o(h_sync_o),
        .h_active_o(h_active),
        
        .v_sync_o(v_sync_o),
        .v_active_o(v_active),
        
        .video_o(video_o)
    );
endmodule
