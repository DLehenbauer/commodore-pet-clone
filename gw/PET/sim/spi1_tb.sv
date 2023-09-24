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

    logic [16:0] spi_addr;              // 17-bit address of pending transaction
    logic  [7:0] spi_wr_data;           // Data from MCU when writing
    logic  [7:0] spi_rd_data;           // Data to MCU when reading
    logic        spi_we;                // Direction (0 = Write, 1 = Read)
    logic        spi_cycle;             // Transaction pending: spi_addr, _data, and _rw_n are valid

    spi1_driver driver(
        .sba_clk_i(clk_sys),
        .sba_addr_o(spi_addr),          // 17-bit address of pending transaction
        .sba_we_o(spi_we),              // Direction (0 = Write, 1 = Read)
        .sba_cycle_o(spi_cycle)         // Transaction pending: spi_addr, _data, and _rw_n are valid
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
 