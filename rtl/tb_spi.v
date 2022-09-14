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

    spi_byte spi_byte_rx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        
        .rx(rx),
        .done(rx_done)
    );

    spi_byte spi_byte_tx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .tx(tx),
        .done(tx_done)
    );

    reg [7:0] last_rx;

    always @(posedge rx_done) begin
        last_rx <= rx;
    end

    task check_done(
        input expected
    );
        assert_equal(rx_done, expected, "rx_done");
        assert_equal(tx_done, expected, "tx_done");
    endtask

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

            $display("[%t] Test: 'done' must be %d after bit %d.", $time, i == 7, i);
            #1 check_done(i == 7);
        end

        $display("[%t] Test: Must receive byte $%x.", $time, data);
        assert_equal(last_rx, data, "last_rx");
    endtask

    task end_xfer;
        #1 tx = 1'bx;
        #1 spi_cs_n = 1;

        #1 $display("[%t] Test: 'done' must be reset by 'cs_n'.", $time);
        check_done(1'b0);
    endtask

    byte values[];

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        $display("[%t] Test: 'done' must be 1 at power on.", $time);
        #1 check_done(1'b1);

        values = new [4];
        values = '{
            8'b11011010,
            8'b01011011
        };

        #1 spi_cs_n = 0;
        #1 spi_cs_n = 1;

        begin_xfer;
        foreach (values[i]) begin
            xfer(/* data: */ values[i]);
        end
        end_xfer;
    end
endmodule
