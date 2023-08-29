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
    logic x = 0;

    logic clk_sys = '0;
    initial forever #(1000 / (64 * 2)) clk_sys = ~clk_sys;

    top top(
        .clk_sys_i(clk_sys)
    );
    
    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, sim);

        #3000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
