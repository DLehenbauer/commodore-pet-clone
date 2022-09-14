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
    reg spi_sclk_src = 0;

    initial begin
        spi_sclk_src = 0;
        forever begin
            #31.25 spi_sclk_src = ~spi_sclk_src;
        end
    end

    reg spi_sclk = 0;
    reg spi_cs_n = 1;
    wire spi_rx;
    wire spi_tx;

    wire [7:0] rx_byte;
    reg  [7:0] tx_byte;
    reg  [2:0] length = 3'd4;
    wire rx_done;
    wire tx_done;

    spi_byte spi_byte_tx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .tx(tx_byte),
        .done(tx_done)
    );

    wire [7:0] rx [4];

    spi_buffer spi_buffer(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .rx(rx),
        .length(length)
    );

    task begin_xfer;
        #1 spi_cs_n = 0;
    endtask

    integer i;

    task xfer_byte(
        input [7:0] data
    );
        tx_byte = data;

        for (i = 0; i < 8; i++) begin
            #1 spi_sclk = 1;
            #1 spi_sclk = 0;
        end
    endtask

    task end_xfer;
        #1 tx_byte = 1'bx;
        #1 spi_cs_n = 1;
    endtask

    integer j;

    task xfer(
        input [2:0] xfer_length,
        input [7:0] byte0,
        input [7:0] byte1,
        input [7:0] byte2,
        input [7:0] byte3
    );
        length = xfer_length;

        begin_xfer;
        xfer_byte(byte0);
        xfer_byte(byte1);
        xfer_byte(byte2);
        xfer_byte(byte3);
        end_xfer;

        assert_equal(rx[0], byte0, "rx[0]");
        assert_equal(rx[1], byte1, "rx[1]");
        assert_equal(rx[2], byte2, "rx[2]");
        assert_equal(rx[3], byte3, "rx[3]");

        length = 3'bxxx;
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 spi_cs_n = 0;
        #1 spi_cs_n = 1;

        xfer(3'd4, 8'h01, 8'h02, 8'h03, 8'h04);

        $finish;
    end
endmodule
