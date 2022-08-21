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
    reg clk = 0;
    wire pi_select;
    wire pi_strobe;
    wire cpu_select;
    wire io_select;
    wire cpu_strobe;

    bus bus(
        .clk16(clk),
        .pi_select(pi_select),
        .pi_strobe(pi_strobe),
        .cpu_select(cpu_select),
        .io_select(io_select),
        .cpu_strobe(cpu_strobe)
    );

    initial begin
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end
    end

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule