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
    input  logic        clk16_i,
    input  logic        pixel_clk_i,
    input  logic        setup_clk_i,
    input  logic        strobe_clk_i,
    input  logic        cpu_en_i,
    input  logic        cclk_en_i,
    input  logic        vram_en_i,
    input  logic        vrom_en_i,
    input  logic        crtc_en_i,
    
    input  logic        rw_ni,
    input  logic        addr_i,
    output logic [13:0] addr_o,
    output logic        addr_oe,
    input  logic  [7:0] data_i,
    input  logic        gfx_i,

    output logic        h_sync_o,
    output logic        v_sync_o,
    output logic        video_o
);
    logic [13:0] ma;
    logic [4:0] ra;
    logic hs, vs, de;

    crtc crtc(
        .reset_i(reset_i),
        .strobe_clk_i(strobe_clk_i),
        .setup_clk_i(setup_clk_i),
        .cclk_en_i(cclk_en_i),
        
        .cs_i(crtc_en_i),
        .rw_ni(rw_ni),
        .rs_i(addr_i),
        .data_i(data_i),

        // .data_o(data_o),
        // .data_oe(data_oe),
        .h_sync_o(hs),
        .v_sync_o(vs),
        .de_o(de),
        .ma_o(ma),
        .ra_o(ra)
    );

    assign addr_o = vrom_en_i
        ? { 2'b1, gfx_i, next_char[6:0], ra[2:0] }
        : { 4'b0000, ma[9:0] };

    assign addr_oe = vram_en_i || vrom_en_i;

    logic [7:0] next_char;

    always_ff @(negedge strobe_clk_i) begin
        if (vram_en_i) next_char <= data_i;
    end

    logic [7:0] next_pixels;

    always_ff @(negedge strobe_clk_i) begin
        if (vrom_en_i) next_pixels <= data_i;
    end

    logic de_q;

    // Synchronize video and h/v sync
    always_ff @(posedge pixel_clk_i) begin
        if (cclk_en_i) de_q <= de;
    end

    // Scanlines exceeding the 8 pixel high character ROM should be blanked.
    // (See 'NO_ROW' signal on sheets 8 and 10 of Universal Dynamic PET.)
    wire no_row = ra[3] || ra[4];

    dotgen dotgen(
        .pixel_clk_i(clk16_i),
        .video_latch(cclk_en_i),
        .pixels_i(next_pixels),
        .display_en_i(de_q && !no_row),
        .reverse_i(next_char[7]),
        .video_o(video_o)
    );

    // PETs with a CRTC invert horiz/vert sync
    assign h_sync_o = !hs;
    assign v_sync_o = !vs;
endmodule
