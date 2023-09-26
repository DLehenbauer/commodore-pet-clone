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

module spi1_tb;
    bit clk_sys = '0;
    initial forever #(1000 / (64 * 2)) clk_sys = ~clk_sys;

    logic [16:0] spi_addr;
    logic  [7:0] spi_wr_data;
    logic  [7:0] spi_rd_data;
    logic        spi_we;
    logic        spi_cycle;

    spi1_driver driver(
        .clk_i(clk_sys),
        .addr_o(spi_addr),
        .we_o(spi_we),
        .cycle_o(spi_cycle)
    );

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, spi1_tb);

        driver.reset();
        driver.write_at(17'h00000, 8'h00);
        driver.read_next(8'h01);
        driver.read_next(8'h01);
        driver.read_next(8'h01);
        driver.read_next(8'h01);
        driver.read_next(8'h01);

        #100

        $display("[%t] Test Complete", $time);
        $finish;
    end
 endmodule
 