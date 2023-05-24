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

    integer addr;

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
        driver.cpu_write(16'h8f18, 8'h0F);      // Volume=15, No Filters

        for (addr = 16'h8f00; addr < 16'h8f15; addr += 7) begin
            driver.cpu_write(addr + 16'd0, 8'hD6);     // Freq = 440 Hz
            driver.cpu_write(addr + 16'd1, 8'h1C);
            driver.cpu_write(addr + 16'd3, 8'h07);     // Pulse Width = 50%
            driver.cpu_write(addr + 16'd4, 8'hff);     //
            driver.cpu_write(addr + 16'd5, 8'h00);     // Attack  = 0, Decay = 0
            driver.cpu_write(addr + 16'd6, 8'hF0);     // Sustain = F, Release = 0
        end

        for (addr = 16'h8f00; addr < 16'h8f15; addr += 7) begin
            driver.cpu_write(addr + 16'd4, 8'b0100_0001);   // Pulse / Trigger
        end

        #2000000;

        driver.ext_reset();

        #1000000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
