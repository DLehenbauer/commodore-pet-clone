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
        $dumpvars(0, sim);

        driver.reset();

        $display("[%t] Verify initial power on state:", $time);
        driver.expect_reset(1);
        driver.expect_ready(0);

        $display("[%t] Verify CPU state combinations:", $time);
        driver.set_cpu(/* reset: */ 0, /* ready: */ 1);
        driver.set_cpu(/* reset: */ 1, /* ready: */ 1);
        driver.set_cpu(/* reset: */ 1, /* ready: */ 0);
        driver.set_cpu(/* reset: */ 0, /* ready: */ 1);

        $display("[%t] SID: Play 440 Hz", $time);
        driver.cpu_write(16'h8f18, 8'h1F);
        driver.cpu_write(16'h8f00, 8'hD6);
        driver.cpu_write(16'h8f01, 8'h1C);
        driver.cpu_write(16'h8f05, 8'h00);
        driver.cpu_write(16'h8f06, 8'hF0);
        driver.cpu_write(16'h8f04, 8'b0001_0001);

        #100000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
