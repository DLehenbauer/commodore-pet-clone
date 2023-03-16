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

    logic reset = '0;
    logic [13:0] addr;
    logic  [7:0] data = 8'h33;
    logic h_sync;
    logic v_sync;
    logic v;

    video video(
        .reset_i(reset),
        .clk16_i(clk16),
        .pixel_clk_i(setup_clk),
        .setup_clk_i(setup_clk),
        .strobe_clk_i(strobe_clk),
        .cclk_en_i(cpu_en),
        .vram_en_i(vram_en),
        .vrom_en_i(vrom_en),
        .addr_o(addr),
        .data_i(data),
        .h_sync_o(h_sync),
        .v_sync_o(v_sync),
        .video_o(v)
    );

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, sim);

        @(negedge clk16);
        reset = 1'b1;
        @(posedge clk16);
        @(posedge clk16);
        reset = '0;

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
