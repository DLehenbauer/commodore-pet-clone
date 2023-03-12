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

    logic h_sync;
    logic v_sync;

    video video(
        .setup_clk_i(setup_clk),
        .cclk_en_i(cpu_en),
        .h_sync_o(h_sync),
        .v_sync_o(v_sync)
    );

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, sim);

        @(posedge h_sync);
        @(posedge v_sync);
        @(posedge v_sync);

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
