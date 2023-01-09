/**
 * PET Clone - Open hardware implementation of the Commodore PET
 * by Daniel Lehenbauer and contributors.
 * 
 * https://github.com/DLehenbauer/commodore-pet-clone
 *
 * To the extent possible under law, I, Daniel Lehenbauer, have waived all
 * copyright and related or neighboring rights to this project. This work is
 * published from the United States.
 *
 * @copyright CC0 http://creativecommons.org/publicdomain/zero/1.0/
 * @author Daniel Lehenbauer <DLehenbauer@users.noreply.github.com> and contributors
 */

module video(
    input  logic        reset_i,
    input  logic        clk16_i,            // 80 cols = 16 MHz pixel clock
    input  logic        clk8_i,             // 40 col  = 8 MHz pixel clock
    input  logic        cclk_i,             // Character clock (always 1 MHz)
    input  logic        video_ram_clk_i,    // Read display ram
    input  logic        video_rom_clk_i,    // Read character rom

    input  logic [16:0] bus_addr_i,         // Incoming addr for CPU reads/writes to CRTC
    output logic [16:0] bus_addr_o,         // Outgoing addr for reading display RAM and char ROM

    input  logic [16:0] pi_addr_i,          // Incoming addr for Pi reading back CRTC registers
    input  logic        pi_read_clk_i,

    input  logic  [7:0] data_i,             // Incoming bus data when writing to CRTC.
    output logic  [7:0] data_o,             // Outgoing bus data when reading from CRTC.
    output logic        data_enable_o,

    input  logic        cpu_write_clk_i,
    input  logic        crtc_select_i,

    output logic        h_sync_o,
    output logic        v_sync_o,
    output logic        video_o
);
    logic [13:0] screen_addr;
    logic [7:0]  h_char_total;
    logic [7:0]  h_char_displayed;
    logic [7:0]  h_sync_start;
    logic [3:0]  h_sync_width;
    logic [4:0]  v_char_pixel_size;
    logic [6:0]  v_char_total;
    logic [6:0]  v_char_displayed;
    logic [6:0]  v_sync_start;
    logic [3:0]  v_sync_width;
    logic [4:0]  v_adjust;

    crtc crtc(
        .reset(reset_i),
        .crtc_select(crtc_select_i),
        .bus_addr(bus_addr_i),
        .bus_data_in(data_i),
        .cpu_write(cpu_write_clk_i),
        .pi_addr(pi_addr_i),
        .pi_read(pi_read_clk_i),
        .crtc_data_out(data_o),
        .crtc_data_out_enable(data_enable_o),

        .screen_addr_o(screen_addr),
        .h_total(h_char_total),
        .h_displayed(h_char_displayed),
        .h_sync_pos(h_sync_start),
        .h_sync_width(h_sync_width),
        .v_total(v_char_total),
        .v_line_adjust(v_adjust),
        .v_displayed(v_char_displayed),
        .v_sync_pos(v_sync_start),
        .v_sync_width(v_sync_width),
        .char_height(v_char_pixel_size)
    );

    logic [13:0] next_char_addr;
    logic [4:0]  next_char_row;
    logic        next_display_enable;
    logic        next_h_sync;
    logic        next_v_sync;

    crtc_sync_gen sync_gen(
        .cclk_i(cclk_i),
        .reset_i(reset_i),

        .screen_addr_i(screen_addr),

        .h_char_total_i(h_char_total),
        .h_char_displayed_i(h_char_displayed),
        .h_sync_start_i(h_sync_start),
        .h_sync_width_i(h_sync_width),

        .v_char_pixel_size_i(v_char_pixel_size),
        .v_char_total_i(v_char_total),
        .v_char_displayed_i(v_char_displayed),
        .v_sync_start_i(v_sync_start),
        .v_sync_width_i(v_sync_width),
        .v_adjust_i(v_adjust),

        .display_enable_o(next_display_enable),
        .h_sync_o(next_h_sync),
        .v_sync_o(next_v_sync),

        .ma_o(next_char_addr),
        .ra_o(next_char_row)
    );

    logic [7:0] next_char;

    always_ff @(negedge video_ram_clk_i) begin
        next_char <= data_i;
    end

    assign bus_addr_o = video_rom_clk_i
        ? { 2'b10, next_char[6:0], next_char_row[2:0] }
        : { 1'b0, next_char_addr };

    logic [7:0] next_pixels;

    always_ff @(negedge video_rom_clk_i) begin
        next_pixels <= data_i;
    end

    dotgen dotgen(
        .reset_i(reset_i),
        .pixel_clk_i(pixel_clk_i),
        .pixels_i(next_pixels),
        .display_enabled_i(next_display_enable),
        .reverse_video_i(next_char[7]),
        .video_o(video_o)
    );

    always_ff @(posedge cclk) begin
        h_sync_o <= next_h_sync;
        v_sync_o <= next_v_sync;
    end
endmodule