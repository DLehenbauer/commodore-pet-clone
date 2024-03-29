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
    input  logic        vram0_en_i,
    input  logic        vrom0_en_i,
    input  logic        vram1_en_i,
    input  logic        vrom1_en_i,
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

    logic col_80_mode = '0;

    always_comb begin
        if (vram0_en_i) begin
            if (col_80_mode) addr_o = { 3'b000, ma[9:0], 1'b0 };
            else addr_o = { 4'b0000, ma[9:0] };
        end
        else if (vrom0_en_i) addr_o = { 2'b1, gfx_i, even_char[6:0], ra[2:0] };
        else if (vram1_en_i) addr_o = { 3'b000, ma[9:0], 1'b1 };
        else if (vrom1_en_i) addr_o = { 2'b1, gfx_i, odd_char[6:0], ra[2:0] };
    end

    assign addr_oe = vram0_en_i || vrom0_en_i || vram1_en_i || vrom1_en_i;

    logic [7:0] even_char, odd_char;

    always_ff @(negedge strobe_clk_i) begin
        if (vram0_en_i) even_char <= data_i;
        if (vram1_en_i) odd_char <= data_i;
    end

    logic [15:0] next_pixels;

    always_ff @(negedge strobe_clk_i) begin
        if (vrom0_en_i) next_pixels[15:8] <= data_i;
        else if (vrom1_en_i) next_pixels[7:0] <= data_i;
    end

    // Scanlines exceeding the 8 pixel high character ROM should be blanked.
    // (See 'NO_ROW' signal on sheets 8 and 10 of Universal Dynamic PET.)
    wire no_row = ra[3] || ra[4];

    logic video_strobe = 1'b0;

    always_ff @(posedge clk16_i) begin
        if (cclk_en_i && setup_clk_i) begin
            video_strobe <= 1'b1;
        end else begin
            video_strobe <= 1'b0;
        end
    end

    dotgen dotgen(
        .clk_i(clk16_i),
        .pixel_clk_en(col_80_mode ? 1'b1 : strobe_clk_i),
        .video_latch(video_strobe),
        .pixels_i(next_pixels),
        .display_en_i(de && !no_row),
        .reverse_i({ even_char[7], odd_char[7] }),
        .video_o(video_o)
    );

    assign h_sync_o = !hs;
    assign v_sync_o = !vs;
endmodule
