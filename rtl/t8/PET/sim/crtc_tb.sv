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

    timing timing(
        .clk16_i(clk16),
        .strobe_clk_o(strobe_clk),
        .setup_clk_o(setup_clk),
        .cpu_en_o(cpu_en)
    );
    
    wire cclk_en = cpu_en;

    logic        res;
    logic        cs;
    logic        rw_n;
    logic        rs;
    logic [7:0]  crtc_data_i;
    logic [7:0]  crtc_data_o;
    logic        crtc_data_oe;
    logic        de;
    logic [13:0] ma;
    logic [4:0]  ra;

    crtc crtc(
        .reset_i(res),
        .strobe_clk_i(strobe_clk),      // Triggers data transfers on bus
        .setup_clk_i(setup_clk),        // Triggers data transfers on bus
        .cclk_en_i(cpu_en),             // Enables character clock (always 1 MHz)
        .cs_i(cs),                      // CRTC selected for data transfer (driven by address decoding)
        .rw_ni(rw_n),                   // Direction of date transfers (0 = writing to CRTC, 1 = reading from CRTC)
        .rs_i(rs),                      // Register select (0 = write address/read status, 1 = read addressed register)
        .data_i(crtc_data_i),           // Transfer data written from CPU to CRTC when CS asserted and /RW is low
        .data_o(crtc_data_o),           // Transfer data read by CPU from CRTC when CS asserted and /RW is high
        .data_oe(crtc_data_oe),         // Asserted when CPU is reading from CRTC
        .h_sync_o(h_sync),              // Horizontal sync
        .v_sync_o(v_sync),              // Vertical sync
        .de_o(de),                      // Display enable
        .ma_o(ma),                      // Refresh RAM address lines
        .ra_o(ra)                       // Raster address lines
    );

    crtc_driver driver(
        .setup_clk_i(setup_clk),
        .strobe_clk_i(strobe_clk),
        .cclk_i(setup_clk && cclk_en_i),
        .res_o(res),
        .cs_o(cs),
        .rs_o(rs),
        .rw_no(rw_n),
        .data_o(crtc_data_i)
    );

    task run;
        $display("[%t] Begin CRTC", $time);

        driver.reset();

        driver.setup('{
            8'd5,       // H Total:      Width of scanline in characters (-1)
            8'd3,       // H Displayed:  Number of characters displayed per scanline
            8'd4,       // H Sync Pos:   Start of horizontal sync pulse in characters
            8'h11,      // Sync Width:   H. Sync = 1 char, V. Sync = 1 scanline
            8'd4,       // V Total:      Height of frame in characters (-1)
            8'd2,       // V Adjust:     Adjustment of frame height in scanlines
            8'd2,       // V Displayed:  Number of characters displayed per frame
            8'd3,       // V Sync Pos:   Position of vertical sync pulse in characters
            8'h00,      // Mode Control: (Unused)
            8'h02,      // Char Height:  Height of one character in scanlines (-1)
            8'h00,      // Cursor Start: (Unused)
            8'h00,      // Cursor End:   (Unused)
            8'h00,      // Display H:    Display start address ([3:0] high bits)
            8'h00       // Display L:    Display start address (low bits)
        });

        // driver.setup('{
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

        driver.reset();

        @(posedge h_sync);
        $display("[%t] HSYNC", $time);

        @(posedge v_sync);
        $display("[%t] VSYNC", $time);

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
