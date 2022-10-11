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
    reg reset    = 1'b1;
    reg spi_cs_n = 1'b1;
    wire spi_rx;
    wire spi_tx;

    wire [7:0] rx_byte;
    reg  [2:0] length = 3'd4;
    wire rx_valid;

    `include "tb_spi_tx.vh"

    spi_byte spi_byte_tx(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_tx(spi_rx),
        .tx(tx_byte)
    );

    wire [7:0] rx [4];

    wire [2:0] rx_count;
    wire valid = rx_count == length;

    spi_buffer spi_buffer(
        .reset(reset),
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .rx(rx),
        .rx_count(rx_count)
    );

    integer byte_index;
    logic unsigned [7:0] bytes [];

    task xfer(
        input [2:0] start_index,
        input [2:0] end_index,
        input [7:0] byte0,
        input [7:0] byte1,
        input [7:0] byte2,
        input [7:0] byte3
    );
        bytes = new [4];
        bytes = '{ byte0, byte1, byte2, byte3 };

        $display("[%t]    Verify buffer contents before transfer:", $time);
        for (byte_index = 0; byte_index < start_index; byte_index++) begin
            $display("[%t]        byte[%0d] == %x", $time, byte_index, bytes[byte_index]);
            #1 assert_equal(rx[byte_index], bytes[byte_index], "rx");
        end

        length = end_index;

        for (byte_index = start_index; byte_index < end_index; byte_index++) begin
            $display("[%t]    Send byte[%0d] == %x", $time, byte_index, bytes[byte_index]);
            xfer_byte(bytes[byte_index]);
        end

        @(posedge valid);

        $display("[%t]    Verify buffer contents after transfer:", $time);
        for (byte_index = 0; byte_index < length; byte_index++) begin
            $display("[%t]        byte[%0d] == %x", $time, byte_index, bytes[byte_index]);
            #1 assert_equal(rx[byte_index], bytes[byte_index], "rx");
        end
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #500 reset = 1'b1;
        #500 reset = 1'b0;

        $display("[%t] Test: Transfer [$aa, $55, $cc, $33]", $time);

        begin_xfer;
        xfer(/* start: */ 3'd0, /* end: */ 3'd4, 8'haa, 8'h55, 8'hcc, 8'h33);
        end_xfer;

        #500 reset = 1'b1;
        #500 reset = 1'b0;

        $display("[%t] Test: Transfer [$0f, $f0, $00, $ff]", $time);
        begin_xfer;
        xfer(/* start: */ 3'd0, /* end: */ 3'd4, 8'h0f, 8'hf0, 8'h00, 8'hff);
        end_xfer;

        #500 reset = 1'b1;
        #500 reset = 1'b0;

        $display("[%t] Test: Transfer [$01], then extend to [$02, $03, $04] ", $time);
        begin_xfer;
        xfer(/* start: */ 3'd0, /* end: */ 3'd1, 8'h01, 8'hxx, 8'hxx, 8'hxx);
        xfer(/* start: */ 3'd1, /* end: */ 3'd4, 8'h01, 8'h02, 8'h03, 8'h04);
        end_xfer;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
