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
    `include "tb_spi_common.vh"

    logic [7:0] rx_byte;
    logic rx_valid;

    spi_byte spi_byte_rx(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx_byte(rx_byte),
        .valid(rx_valid)
    );

    task check_valid(
        input expected
    );
        assert_equal(rx_valid, expected, "rx_valid");
        assert_equal(tx_valid, expected, "tx_valid");
    endtask

    always @(negedge spi_cs_n) begin
        $display("[%t]    'valid' must be reset by 'cs_n'.", $time);
        #1 check_valid(1'b0);
    end

    task xfer(
        input [7:0] data,
        input logic [7:0] next_tx = 8'hxx,
        input integer num_bits = 8
    );
        xfer_bits(next_tx, num_bits);

        if (num_bits == 8) begin
            $display("[%t]    Must receive byte $%x.", $time, data);
            @(posedge rx_valid);
            assert_equal(rx_byte, data, "rx_byte");
            assert_equal(spi_sclk, 1, "spi_sclk");
            @(negedge rx_valid);
            assert_equal(spi_sclk, 1, "spi_sclk");
            @(negedge spi_sclk);
        end
    endtask

    integer i;
    byte values[];

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        $display("[%t] Test: 'valid' must be 0 at power on.", $time);
        #1 check_valid(1'b0);

        $display("[%t] Test: Toggle cs_n after power on.", $time);
        values = new [4];
        values = '{
            8'b11011010,
            8'b01011011
        };

        foreach (values[i]) begin
            $display("[%t] Test: Transfer single byte $%h.", $time, values[i]);

            // MSB of 'tx_byte' is preloaded while spi_cs_n is high on rising edge of sys_clk.
            begin_xfer(/* tx: */ values[i]);
            xfer(/* data: */ values[i]);
            end_xfer;
        end


        $display("[%t] Test: Transfer consecutive bytes $%h $%h.", $time, values[0], values[1]);

        begin_xfer(/* tx: */ values[0]);
        foreach (values[i]) begin
            xfer(/* tx: */ values[i], /* next_tx: */ values[i + 1]);
        end
        end_xfer;

        for (i = 0; i < 8; i++) begin
            $display("[%t] Test: Toggling cs_n after %0d bits resets spi state.", $time, i);
            begin_xfer(/* tx: */ values[0]);
            xfer(/* data: */ values[0], /* next_tx: */ 8'hxx, /* num_bits: */ i);
            end_xfer;

            $display("[%t] Test: Transfers correctly after toggling cs_n.", $time);
            begin_xfer(/* tx: */ values[0]);
            xfer(/* data: */ values[0]);
            end_xfer();
        end

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
