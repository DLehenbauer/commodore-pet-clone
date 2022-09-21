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
    reg spi_sclk = 1'b0;
    reg spi_cs_n = 1'b1;

    wire spi_tx;
    reg spi_rx;

    wire [16:0] pi_addr;
    wire [7:0]  pi_data_out;
    wire pi_rw_b;
    reg pi_pending_in = 1'b0;
    wire pi_pending_out;

    wire [7:0] rx_byte;
    reg  [7:0] tx_byte;
    wire byte_valid;

    spi_byte spi_byte_tx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .rx(rx_byte),
        .tx(tx_byte),
        .valid(byte_valid)
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
        spi_cs_n = 1'b0;
        #500;
    endtask

    integer bit_index;

    task xfer_byte(
        input [7:0] data
    );
        tx_byte = data;

        for (bit_index = 0; bit_index < 8; bit_index++) begin
            spi_sclk = 1'b1;
            #500;
            spi_sclk = 1'b0;
            #500;
        end
    endtask

    task end_xfer;
        tx_byte = 8'hxx;
        spi_cs_n = 1'b1;
        #500;
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 pi_pending_in = 1'b1;

        begin_xfer;
        xfer_byte(8'h40);
        end_xfer;

        begin_xfer;
        xfer_byte(8'h55);
        end_xfer;

        begin_xfer;
        xfer_byte(8'h81);
        end_xfer;
        
        begin_xfer;
        xfer_byte(8'h7e);
        end_xfer;

        @(posedge pi_pending_out);
        assert_equal(pi_addr, 17'h15581, "pi_addr");
        assert_equal(pi_data_out, 8'h7e, "pi_data_out");
        assert_equal(pi_rw_b, 1'b0, "pi_rw_b");
        
        #100 pi_done_in = 1'b0;
        #100 pi_pending_in = 1'b0;
        #100 $finish;
    end
endmodule
