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
    reg spi_cs_n = 0;
    reg spi_rx = 1'bx;

    wire [7:0] rx;
    wire done;

    spi_byte spi_byte(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        
        .rx(rx),
        .done(done)
    );

    reg [7:0] last_rx;

    always @(posedge done) begin
        last_rx <= rx;
    end

    reg [7:0] mosi_data;
    integer i;

    task begin_xfer;
        #1 spi_cs_n = 0;
    endtask

    task xfer(
        input [7:0] data
    );
        mosi_data = data;

        for (i = 0; i < 8; i++) begin
            #1 spi_rx = mosi_data[7];
            mosi_data[7:1] <= mosi_data[6:0];
            #1 spi_sclk = 1;

            $display("[%t] Test: 'done' must be %d after bit %d.", $time, i === 7, i);
            #1 assert_equal(done, i === 7, "done");
            
            #1 spi_sclk = 0;

            #1 assert_equal(done, i === 7, "done");
        end

        $display("[%t] Test: Must receive byte $%x.", $time, data);
        assert_equal(last_rx, data, "last_rx");
    endtask

    task end_xfer;
        #1 spi_rx = 1'bx;
        #1 spi_cs_n = 1;

        $display("[%t] Test: 'done' must be reset by 'cs_n'.", $time);
        #1 assert_equal(done, 1'b0, "done");
    endtask

    byte values[];

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        $display("[%t] Test: 'done' must be low at power on.", $time);
        assert_equal(done, 1'b0, "done");        

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