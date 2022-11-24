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

module spi_driver (
    input  logic clk_sys_i,
    output logic spi_sclk_o,
    output logic spi_cs_no,
    output logic spi_tx_o
);
    bit start_sclk = '0;

    always @(posedge start_sclk) begin
        while (start_sclk) begin
            #250
            spi_sclk_o <= '1;
            #500;
            spi_sclk_o <= '0;
            #250;
        end
    end

    task reset;
        spi_cs_no = '0;
        @(posedge clk_sys_i);
        spi_sclk_o = '0;
        spi_cs_no = '1;
        @(posedge clk_sys_i);
    endtask

    task begin_xfer(
        input byte tx_i
    );
        assert(spi_cs_no == 1'b1);

        // MSB of 'tx_byte' is preloaded while spi_cs_no is high on rising edge of clk_sys.
        tx_byte = tx_i;
        @(posedge clk_sys_i);

        spi_cs_no = '0;
        #500;
        start_sclk = '1;
    endtask

    integer bit_index;

    task xfer_bits(
        input logic [7:0] next_tx = 8'hxx,
        input integer num_bits = 8
    );
        for (bit_index = 0; bit_index < num_bits; bit_index++) begin
            @(posedge spi_sclk_o);

            // 'tx_byte' is loaded on falling edge of spi_sclk_o when the last bit is transfered.
            // However, we update 'tx_byte' after every bit to verify that 'tx_byte' is held
            // between loads.
            tx_byte = next_tx;
        end
    endtask

    task end_xfer(
        input bit next_cs_ni = 1'b1
    );
        `assert_equal(spi_cs_no, 1'b0);

        start_sclk = 0;

        #500;
        spi_cs_no = next_cs_ni;

        #500;
    endtask

    task xfer_bytes(
        input logic unsigned [7:0] tx[]
    );
        integer i;
        
        // string s;
        // s = "";
        // foreach (tx[i]) s = { s, $sformatf("%h ", tx[i]) };
        // $display("[%t] SPI Send: [ %s]", $time, s);

        // 'tx_byte' is continuously preloaded from falling edge of CS_N.
        spi_driver.begin_xfer(tx[0]);

        foreach(tx[i]) begin
            // 'next_tx' is the next byte to load on the 8th falling edge of SCLK.
            spi_driver.xfer_bits(tx[i + 1]);
        end
    endtask

    logic       tx_valid;
    logic [7:0] tx_byte = 8'hxx;

    spi_byte spi_byte_tx(
        .clk_sys_i(clk_sys_i),
        .spi_sclk_i(spi_sclk_o),
        .spi_cs_ni(spi_cs_no),
        .spi_tx_o(spi_tx_o),
        .tx_byte_i(tx_byte),
        .valid_o(tx_valid)
    );
endmodule

module tb();
    bit clk_sys = '0;
    initial forever #31.25 clk_sys = ~clk_sys;

    logic spi_sclk;
    logic spi_cs_n;
    logic spi_rx;

    spi_driver spi_driver(
        .clk_sys_i(clk_sys),
        .spi_sclk_o(spi_sclk),
        .spi_cs_no(spi_cs_n),
        .spi_tx_o(spi_rx)
    );

    logic spi_tx;
    logic [7:0] rx_byte;
    logic rx_valid;

    spi_byte spi_byte_rx(
        .clk_sys_i(clk_sys),
        .spi_sclk_i(spi_sclk),
        .spi_cs_ni(spi_cs_n),
        .spi_rx_i(spi_tx),
        .rx_byte_o(rx_byte),
        .valid_o(rx_valid)
    );

    logic [7:0] last_rx_byte;
    always @(posedge rx_valid) last_rx_byte <= rx_byte;

    logic [16:0] spi_addr;
    logic [7:0] spi_data_in;
    logic [7:0] spi_data_out;
    logic spi_rw_b;
    logic spi_valid;
    logic spi_ready_in = 1'b0;
    logic spi_ready_out;

    spi_bridge spi_bridge(
        .clk_sys_i(clk_sys),
        .spi_sclk_i(spi_sclk),
        .spi_cs_ni(spi_cs_n),
        .spi_rx_i(spi_rx),
        .spi_tx_io(spi_tx),
        .spi_addr_o(spi_addr),
        .spi_data_i(spi_data_in),
        .spi_data_o(spi_data_out),
        .spi_rw_no(spi_rw_b),
        .spi_valid_o(spi_valid),
        .spi_ready_i(spi_ready_in),
        .spi_ready_o(spi_ready_out)
    );

    task check(
        input pending,
        input rw_b,
        input [16:0] addr,
        input [7:0] data
    );
        `assert_equal(spi_ready_in, '0);

        $display("[%t]    expect(pending: %d, rw_b: %d, addr: $%x, data: $%x)",
            $time, spi_valid, spi_rw_b, spi_addr, spi_data_out);

        `assert_equal(spi_valid, pending);
        `assert_equal(spi_rw_b, rw_b);
        `assert_equal(spi_addr, addr);

        if (!rw_b) begin
            `assert_equal(spi_data_out, data);
        end else begin
            `assert_equal(last_rx_byte, data);
        end

        spi_ready_in = 1'b1;
        @(posedge clk_sys);
        @(posedge clk_sys);
        #1 `assert_equal(spi_ready_out, 1'b1);

        spi_driver.end_xfer;

        @(posedge clk_sys);
        `assert_equal(spi_valid, 1'b0);
        `assert_equal(spi_ready_out, 1'b0);

        spi_ready_in = '0;
        spi_driver.reset;
    endtask

    task send(
        logic unsigned [7:0] tx[]
    );
        integer i;
        string s;

        s = $sformatf(" %%%b ", tx[0]);
        for (i = 1; i < tx.size(); i++) begin
            s = { s, $sformatf("%h ", tx[i]) };
        end

        $display("[%t]    send -> [%s]", $time, s);
        spi_driver.xfer_bytes(tx);
        spi_driver.end_xfer(/* next_cs_ni: */ 1'b0);
    endtask

    function [7:0] cmd(input bit rw_n, input bit set_addr, input logic [16:0] addr);
        return { rw_n, set_addr, 5'bxxxxx, addr[16] };
    endfunction

    function [7:0] addr_hi(input logic [16:0] addr);
        return addr[15:8];
    endfunction

    function [7:0] addr_lo(input logic [16:0] addr);
        return addr[7:0];
    endfunction

    task write_at(
        input [16:0] addr,
        input [7:0] data
    );
        send('{
            cmd( /* rw_n: */ 1'b0, /* set_addr: */ 1'b1, addr ),
            data,
            addr_hi(addr),
            addr_lo(addr)
        });

        check(/* pending: */ 1'b1, /* rw_b: */ 1'b0, /* addr: */ addr, /* data: */ data);
    endtask

    task read_at(
        input [16:0] addr,
        input [7:0] data
    );
        spi_data_in = data;

        send('{
            cmd( /* rw_n: */ 1'b1, /* set_addr: */ 1'b1, addr ),
            addr_hi(addr),
            addr_lo(addr)
        });

        check(/* pending: */ 1'b1, /* rw_b: */ 1'b1, /* addr: */ addr, /* data: */ data);
    endtask

    task read_next(
        input [16:0] addr,
        input [7:0] data
    );
        spi_data_in = data;

        send('{
            cmd( /* rw_n: */ 1'b1, /* set_addr: */ 1'b0, addr )
        });

        check(/* pending: */ 1'b1, /* rw_b: */ 1'b1, /* addr: */ addr, /* data: */ data);
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        spi_driver.reset;

        write_at(/* addr: */ 17'h8000, /* data: */ 8'h55);
        read_at(/* addr: */ 17'h8000, /* data: */ 8'h55);
        read_next(/* addr: */ 17'h8001, /* data: */ 8'h55);
        write_at(/* addr: */ 17'h8001, /* data: */ 8'h55);
        read_at(/* addr: */ 17'h8001, /* data: */ 8'h55);
        read_next(/* addr: */ 17'h8002, /* data: */ 8'h55);

        #500 $finish;
    end
endmodule
