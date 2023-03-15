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

    logic [7:0] next_char;

    always_ff @(negedge strobe_clk_i) begin
        if (vram_en_i) begin
            next_char <= data_i;
        end
    end

    assign addr_o = vrom_en_i
        ? { 2'b10, next_char[6:0], ra[2:0] }
        : { 4'b0000, ma[9:0] };

    assign addr_oe = vram_en_i || vrom_en_i;

    logic [7:0] next_pixels;

    always_ff @(negedge strobe_clk_i) begin
        if (vrom_en_i) begin
            next_pixels <= data_i;
        end
    end

    logic de_q;

    // Synchronize video and h/v sync
    always_ff @(posedge pixel_clk_i) begin
        if (cclk_en_i) begin
            h_sync_o <= !hs;        // DynaPet inverts horiz/vert sync
            v_sync_o <= !vs;
            de_q     <= de;
        end
    end

    dotgen dotgen(
        .reset_i(cclk_en_i),
        .pixel_clk_i(pixel_clk_i),
        .pixels_i(next_pixels),
        .display_en_i(de_q),
        .reverse_i(next_char[7]),
        .video_o(video_o)
    );
endmodule
