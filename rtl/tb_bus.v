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

module tb();
    reg clk16 = 0;

    initial begin
        clk16 = 0;
        forever begin
            #31.25 clk16 = ~clk16;
        end
    end

    wire pi_select;
    wire pi_strobe;
    wire video_select;
    wire video_ram_strobe;
    wire video_rom_strobe;
    wire cpu_select;
    wire io_select;
    wire cpu_strobe;

    bus bus(
        .clk16(clk16),
        .pi_select(pi_select),
        .pi_strobe(pi_strobe),
        .video_select(video_select),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),
        .cpu_select(cpu_select),
        .io_select(io_select),
        .cpu_strobe(cpu_strobe)
    );

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule