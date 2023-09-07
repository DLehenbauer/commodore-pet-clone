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

module main_tb;
    bit clk_sys = '0;
    initial forever #(1000 / (64 * 2)) clk_sys = ~clk_sys;

    logic sck;
    logic cs_n;
    logic pico;
    logic poci;
    logic ready;

    spi_driver spi(
        .spi_cs_no(cs_n),
        .spi_sck_o(sck),
        .spi_tx_o(pico),
        .spi_rx_i(poci)
    );

    main main(
        .clk_sys_i(clk_sys),
        .spi1_cs_ni(cs_n),
        .spi1_sck_i(sck),
        .spi1_rx_i(pico),
        .spi1_tx_o(poci),
        .spi_ready_o(ready)
    );

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, main_tb);

        spi.reset();
        spi.send('{ 8'haa, 8'h55, 8'h00 });

        #1000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
 endmodule
 