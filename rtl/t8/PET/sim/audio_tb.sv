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

module audio_tb;
    logic clk16 = '0;
    initial forever #(1000 / (16 * 2)) clk16 = ~clk16;

    audio_driver audio(
        .clk16_i(clk16),
        .audio_o(a)
    );

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, audio_tb);

        audio.reset;
        audio.master_vol(4'hf);
        audio.voice1_freq(16'h1CD6);
        audio.voice1_adsr(4'h1, 4'h2, 4'hf, 4'h3);
        audio.voice1_on();

        #1000000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
