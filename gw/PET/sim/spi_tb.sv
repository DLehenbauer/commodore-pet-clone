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

module spi_tb;
    logic sck;
    logic cs_n;
    logic pico;
    logic poci;
    logic [7:0] tx;
    logic [7:0] rx;
    logic valid;

    spi_driver controller(
        .spi_cs_no(cs_n),
        .spi_sck_o(sck),
        .spi_tx_o(pico),
        .spi_rx_i(poci)
    );

    spi_byte peripheral(
        .spi_cs_ni(cs_n),
        .spi_sck_i(sck),
        .spi_tx_o(poci),
        .spi_rx_i(pico),
        .tx_byte_i(tx),
        .rx_byte_o(rx),
        .rx_valid_o(valid)
    );

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, spi_tb);

        controller.reset();
        tx = 8'h55;
        controller.send('{ 8'haa });

        $display("[%t] Test Complete", $time);
        $finish;
    end
 endmodule
 