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
    input  logic setup_clk_i,
    input  logic cclk_en_i,
    output logic h_sync_o,
    output logic v_sync_o,
    output logic video_o
);
    logic [16:0] vram_addr;

    logic [13:0] ma;
    logic [4:0] ra;
    logic de;

    crtc crtc(
        //.reset_i(reset_i),
        //.strobe_clk_i(strobe_clk_i),
        .setup_clk_i(setup_clk_i),
        .cclk_en_i(cclk_en_i),
        
        // .cs_i(cs_i),
        // .rw_ni(rw_ni),
        // .rs_i(rs_i),
        // .data_i(data_i),
        // .data_o(data_o),
        // .data_oe(data_oe),
        .h_sync_o(h_sync_o),
        .v_sync_o(v_sync_o),
        .de_o(de),
        .ma_o(ma),
        .ra_o(ra)
    );

    assign vram_addr = { 7'h20, ma[9:0] };

    assign video_o = de;
endmodule
