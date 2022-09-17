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
    reg spi_sclk;
    reg spi_cs_n = 1'b1;

    initial begin
        spi_sclk = 0;
        forever begin
            #31.25 spi_sclk = ~spi_sclk;
        end
    end

    wire spi_tx;
    reg spi_rx;

    wire [16:0] pi_addr;
    wire [7:0]  pi_data_out;
    wire pi_rw_b;
    reg pi_pending_in = 1'b0;
    wire pi_pending_out;

    wire [7:0] rx_byte;
    reg  [7:0] tx_byte;
    wire byte_done;

    spi_byte spi_byte_tx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .rx(rx_byte),
        .tx(tx_byte),
        .done(byte_done)
    );

    reg pi_done_in = 1'b0;
    wire pi_done_out;

    pi_com pi_com(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .pi_addr(pi_addr),
        .pi_data_out(pi_data_out),
        .pi_rw_b(pi_rw_b),
        .pi_pending_in(pi_pending_in),
        .pi_pending_out(pi_pending_out),
        .pi_done_in(pi_done_in),
        .pi_done_out(pi_done_out)
    );

    task begin_xfer;
        @(negedge spi_sclk);
        #1;                 // SCLK must be low prior to falling edge of CS_N.
        spi_cs_n = 0;
    endtask

    integer i;

    task xfer_byte(
        input [7:0] data
    );
        tx_byte = data;

        for (i = 0; i < 8; i++) begin
            @(posedge spi_sclk);
            @(negedge spi_sclk);
        end
    endtask

    task end_xfer;
        @(negedge spi_sclk);
        spi_cs_n = 1'b1;
        #1 tx_byte = 1'bx;
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 pi_pending_in = 1'b1;

        begin_xfer;
        xfer_byte(8'haa);
        xfer_byte(8'h55);
        xfer_byte(8'h81);
        xfer_byte(8'h7e);
        end_xfer;

        #100 pi_done_in = 1'b1;

        @(posedge pi_done_out);
        #100 pi_done_in = 1'b0;
        #100 pi_pending_in = 1'b0;
        #100 $finish;
    end
endmodule
