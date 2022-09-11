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
    reg sclk = 0;
    reg cs_n = 0;
    reg mosi = 1'bx;

    wire [7:0] rx;
    wire done;

    spi_slave spi(
        .spi_sclk(sclk),
        .spi_cs_n(cs_n),
        .spi_mosi(mosi),
        
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
        #1 cs_n = 0;
    endtask

    task xfer(
        input [7:0] data
    );
        mosi_data = data;

        for (i = 0; i < 8; i++) begin
            #1 mosi = mosi_data[7];
            mosi_data[7:1] <= mosi_data[6:0];
            #1 sclk = 1;
            #1 sclk = 0;
        end

        assert_equal(last_rx, data, "last_rx");
        assert_equal(done, 1'b1, "done");
    endtask

    task end_xfer;
        #1 mosi = 1'bx;
        #1 cs_n = 1;
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        begin_xfer;
        xfer(/* data: */ 8'hf0);
        xfer(/* data: */ 8'h0f);
        xfer(/* data: */ 8'hf0);
        xfer(/* data: */ 8'h0f);
        end_xfer;
    end
endmodule