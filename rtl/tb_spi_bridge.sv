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
    bit clk_sys = '0;
    initial forever #31.25 clk_sys = ~clk_sys;

    logic [16:0] spi_addr;
    logic  [7:0] spi_data_in;
    logic  [7:0] spi_data_out;
    logic        spi_rw_n;
    logic        spi_valid;
    logic        spi_ready_in;
    logic        spi_ready_out;

    spi_bridge_driver driver(
        .clk_sys_i(clk_sys),
        .spi_addr_o(spi_addr),
        .spi_data_i(spi_data_in),
        .spi_data_o(spi_data_out),
        .spi_rw_no(spi_rw_n),
        .spi_valid_o(spi_valid),
        .spi_ready_i(spi_ready_in),
        .spi_ready_o(spi_ready_out)
    );

    task write_at(
        input [16:0] addr_i,
        input [7:0] data_i
    );
        driver.write_at(/* addr_i: */ addr_i, /* data_i: */ data_i);
    endtask

    task read_at(
        input [16:0] addr_i,
        input  [7:0] data_i
    );
        spi_data_in = data_i;
        driver.read_at(addr_i);
        `assert_equal(driver.last_rx_byte, data_i);
    endtask

    task read_next(
        input [16:0] addr_i,
        input [7:0] data_i
    );
        spi_data_in = data_i;
        driver.read_next(addr_i);
        `assert_equal(driver.last_rx_byte, data_i);
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        driver.reset;
        write_at(/* addr: */ 17'h8000, /* data: */ 8'h55);
        read_at(/* addr: */ 17'h8000, /* data: */ 8'h55);
        read_next(/* addr: */ 17'h8001, /* data: */ 8'h55);
        write_at(/* addr: */ 17'h8001, /* data: */ 8'h55);
        read_at(/* addr: */ 17'h8001, /* data: */ 8'h55);
        read_next(/* addr: */ 17'h8002, /* data: */ 8'h55);

        #500 $finish;
    end
endmodule
