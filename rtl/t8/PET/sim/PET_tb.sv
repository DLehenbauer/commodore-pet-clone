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
    top_driver driver();

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars;

        driver.reset();
        driver.mcu.write_at(17'h035e, 8'hff);
        driver.mcu.read_at(17'h035e);

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
