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

module tb();
    reg spi_sclk = 0;
    reg spi_cs_n = 1;
    wire spi_rx;
    wire spi_tx;

    wire [7:0] rx;
    reg  [7:0] tx;
    wire rx_done;
    wire tx_done;

    spi_byte spi_byte_tx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .tx(tx),
        .done(tx_done)
    );

    wire [16:0] pi_addr;
    wire [7:0] pi_data;
    wire pi_rw_b;
    wire pi_pending;

    pi_register pi_register(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .pi_addr(pi_addr),
        .pi_data(pi_data),
        .pi_rw_b(pi_rw_b),
        .pi_pending(pi_pending)
    );

    task begin_xfer;
        #1 spi_cs_n = 0;
    endtask

    integer i;

    task xfer(
        input [7:0] data
    );
        tx = data;

        for (i = 0; i < 8; i++) begin
            #1 spi_sclk = 1;
            #1 spi_sclk = 0;
        end
    endtask

    task end_xfer;
        #1 tx = 1'bx;
        #1 spi_cs_n = 1;
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 spi_cs_n = 0;
        #1 spi_cs_n = 1;

        begin_xfer;
        xfer(/* value: */ 8'h00);
        xfer(/* value: */ 8'h80);
        xfer(/* value: */ 8'h00);
        end_xfer;
    end
endmodule
