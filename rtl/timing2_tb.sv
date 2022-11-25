`timescale 1ns / 1ps

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

module tb_timing();
    logic clk_16 = 0;
    initial forever #31.25 clk_16 = ~clk_16;

    logic clk_8;

    logic spi_enable;

    timing2 timing(
        .clk_16_i(clk_16),
        .clk_8_o(clk_8),
        .spi_enable_o(spi_enable)
    );

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
