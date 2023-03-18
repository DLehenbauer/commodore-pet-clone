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

`timescale 1ns / 1ps

module sim;
    logic clk16 = '0;
    initial forever #(1000 / (16 * 2)) clk16 = ~clk16;

    logic strobe_clk;
    logic setup_clk;
    logic cpu_en;
    logic vram_en;
    logic vrom_en;

    timing timing(
        .clk16_i(clk16),
        .strobe_clk_o(strobe_clk),
        .setup_clk_o(setup_clk),
        .cpu_en_o(cpu_en),
        .vram_en_o(vram_en),
        .vrom_en_o(vrom_en)
    );

    wire cclk_en = cpu_en;

    logic        reset;
    logic  [7:0] crtc_data_i;

    crtc_driver driver(
        .setup_clk_i(setup_clk),
        .strobe_clk_i(strobe_clk),
        .cclk_i(setup_clk && cclk_en_i),
        .res_o(reset),
        .cs_o(cs),
        .rs_o(rs),
        .rw_no(rw_n),
        .data_o(crtc_data_i)
    );

    logic [13:0] addr_o;
    logic h_sync;
    logic v_sync;
    logic v;

    logic [7:0] char_i      = 8'hc0;
    logic [7:0] pixels_i    = 8'h33;
    logic [7:0] data_i;

    always_comb begin
        if (cs) data_i = crtc_data_i;
        else if (vram_en) data_i = char_i;
        else if (vrom_en) data_i = pixels_i;
        else data_i = 8'hxx;
    end

    video video(
        .reset_i(reset),
        .clk16_i(clk16),
        .pixel_clk_i(setup_clk),
        .setup_clk_i(setup_clk),
        .strobe_clk_i(strobe_clk),
        .cclk_en_i(cpu_en),
        .vram_en_i(vram_en),
        .vrom_en_i(vrom_en),
        .crtc_en_i(cs),
        .rw_ni(rw_n),
        .addr_i(rs),
        .addr_o(addr_o),
        .data_i(data_i),
        .h_sync_o(h_sync),
        .v_sync_o(v_sync),
        .video_o(v)
    );

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, sim);

        driver.setup('{
            8'd5,       // H Total:      Width of scanline in characters (-1)
            8'd3,       // H Displayed:  Number of columns displayed per row
            8'd4,       // H Sync Pos:   Start of horizontal sync pulse in characters
            8'h11,      // Sync Width:   H. Sync = 1 char, V. Sync = 1 scanline
            8'd4,       // V Total:      Height of frame in rows (-1)
            8'd2,       // V Adjust:     Adjustment of frame height in scanlines
            8'd2,       // V Displayed:  Number of rows displayed per frame
            8'd3,       // V Sync Pos:   Position of vertical sync pulse in characters
            8'h00,      // Mode Control: (Unused)
            8'h02,      // Char Height:  Height of one character in scanlines (-1)
            8'h00,      // Cursor Start: (Unused)
            8'h00,      // Cursor End:   (Unused)
            8'h00,      // Display H:    Display start address ([3:0] high bits)
            8'h00       // Display L:    Display start address (low bits)
        });

        driver.reset();

        @(posedge h_sync);
        $display("H-Sync");
        @(posedge v_sync);
        $display("V-Sync");
        @(posedge v_sync);
        $display("V-Sync");

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
