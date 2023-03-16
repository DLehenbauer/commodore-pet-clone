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
    logic h_sync;
    logic v_sync;

    crtc_driver crtc(
        .h_sync_o(h_sync),
        .v_sync_o(v_sync)
    );

    task run();
        $display("[%t] Begin CRTC", $time);

        crtc.reset();

        crtc.setup('{
            8'd5,       // H Total:      Width of scanline in characters (-1)
            8'd3,       // H Displayed:  Number of characters displayed per scanline
            8'd4,       // H Sync Pos:   Start of horizontal sync pulse in characters
            8'h11,      // Sync Width:   H. Sync = 1 char, V. Sync = 1 scanline
            8'd4,       // V Total:      Height of frame in characters (-1)
            8'd0,       // V Adjust:     Adjustment of frame height in scanlines
            8'd2,       // V Displayed:  Number of characters displayed per frame
            8'd3,       // V Sync Pos:   Position of vertical sync pulse in characters
            8'h00,      // Mode Control: (Unused)
            8'h02,      // Char Height:  Height of one character in scanlines (-1)
            8'h00,      // Cursor Start: (Unused)
            8'h00,      // Cursor End:   (Unused)
            8'h00,      // Display H:    Display start address ([3:0] high bits)
            8'h00       // Display L:    Display start address (low bits)
        });

        // crtc.setup('{
        //     8'd49,      // H Total:      Width of scanline in characters (-1)
        //     8'd40,      // H Displayed:  Number of characters displayed per scanline
        //     8'd41,      // H Sync Pos:   Start of horizontal sync pulse in characters
        //     8'h0f,      // Sync Width:   H. Sync = 15 char, V. Sync = 16 scanline
        //     8'd40,      // V Total:      Height of frame in characters (-1)
        //     8'd05,      // V Adjust:     Adjustment of frame height in scanlines
        //     8'd25,      // V Displayed:  Number of characters displayed per frame
        //     8'd33,      // V Sync Pos:   Position of vertical sync pulse in characters
        //     8'd00,      // Mode Control: (Unused)
        //     8'd07,      // Char Height:  Height of one character in scanlines (-1)
        //     8'h00,      // Cursor Start: (Unused)
        //     8'h00,      // Cursor End:   (Unused)
        //     8'h00,      // Display H:    Display start address ([3:0] high bits)
        //     8'h00       // Display L:    Display start address (low bits)
        // });

        crtc.reset();

        @(posedge h_sync);
        $display("[%t] HSYNC", $time);

        @(posedge v_sync);
        $display("[%t] VSYNC", $time);

        @(posedge v_sync);
        $display("[%t] VSYNC", $time);

        $display("[%t] End CRTC", $time);
    endtask

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, sim);

        run();

        $finish;
    end
endmodule
