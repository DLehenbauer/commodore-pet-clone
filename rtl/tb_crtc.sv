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
`include "assert.svh"

module tb();
    logic        reset       = '0;

    logic [16:0] bus_addr    = 'x;
    logic [7:0]  bus_data_in = '0;
    logic        bus_rw_n    = '0;

    logic        cpu_read    = '0;
    logic        cpu_write   = '0;

    logic [15:0] spi_addr    = 'x;
    logic        spi_read    = '0;

    logic [7:0] crtc_data_out;
    logic       crtc_data_out_enable;

    logic [4:0] crtc_address_register;
    logic [7:0] crtc_r;

    address_decoding address_decoding(
        .bus_addr_i(bus_addr),
        .crtc_en_o(crtc_enable)
    );

    crtc ctrc(
        .reset(reset),

        .crtc_select(crtc_enable),
        .bus_addr(bus_addr),
        .bus_data_in(bus_data_in),
        .cpu_write(cpu_write),

        .pi_addr(spi_addr),
        .pi_read(spi_read),

        .crtc_data_out(crtc_data_out),
        .crtc_data_out_enable(crtc_data_out_enable),

        .crtc_address_register(crtc_address_register),
        .crtc_r(crtc_r)
    );

    task cpu_select(
        input logic [4:0] r
    );
        #1 bus_data_in = { 3'b000, r };
        #1 bus_addr = 17'he880;
        #1 cpu_write = 1'b1;
        #1 cpu_write = 0;

        #1 `assert_equal(crtc_address_register, r);
    endtask

    task cpu_store(
        input logic [7:0] value
    );
        #1 bus_data_in = value;
        #1 bus_addr = 17'he881;
        #1 cpu_write = 1'b1;
        #1 cpu_write = 0;

        #1 `assert_equal(crtc_r, value);

        bus_data_in = 8'hxx;
        bus_addr    = 17'hxxxxx;
    endtask

    // task cpu_load(
    //     input logic [7:0] expected_value
    // );
    //     #1 bus_data_in = 8'hxx;
    //     #1 bus_addr = 17'he881;
    //     #1 cpu_read = 1'b1;
    //     #1 `assert_equal(bus_data_out, expected_value);
    //     #1 cpu_read = 0;
    //     bus_addr = 17'hxxxxx;
    // endtask

    task spi_load(
        input logic [4:0] r,
        input logic [7:0] expected_value
    );
        spi_addr = 16'he8f0 | r;

        #1 spi_read = 1'b1;
        #1 `assert_equal(crtc_data_out_enable, 1);

        #1 spi_read = 0;
        #1 `assert_equal(crtc_data_out, expected_value);
        `assert_equal(crtc_data_out_enable, 1);

        #1 spi_addr = 16'h0;
    endtask

    integer r;
    logic [7:0] value;

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 reset = 1;
        #1 reset = 0;

        for (r = 0; r <= 15; r++) begin
            #1 $display("[%t] Test: CPU select R%0d", $time, r);
            cpu_select(/* r: */ r);

            value = 8'h80 | r;

            #1 $display("[%t] Test: CPU store R%0d = $%x", $time, r, value);
            cpu_store(/* value: */ value);

            // #1 $display("[%t] Test: CPU load R%0d = $%x", $time, r, value);
            // cpu_load(/* expected_value: */ value);

            #1 $display("[%t] Test: SPI load R%0d == $%x", $time, r, value);
            spi_load(r, value);
        end

        for (r = 16; r <= 17; r++) begin
            #1 $display("[%t] Test: CPU select R%0d", $time, r);
            cpu_select(/* r: */ r);

            value = 8'h80 | r;

            #1 $display("[%t] Test: CPU store R%0d = $%x", $time, r, value);
            cpu_store(/* value: */ value);
        end

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
