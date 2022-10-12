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
    reg spi_cs_n = 1'b1;
    wire spi_rx;
    wire spi_tx;
    wire [7:0] rx_byte;
    wire spi_valid;

    spi_byte spi_byte_tx(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .rx(rx_byte),
        .tx(tx_byte),
        .valid(spi_valid)
    );

    `include "tb_spi_tx.vh"

    reg [7:0] last_rx_byte;

    always @(posedge spi_valid) last_rx_byte <= rx_byte;

    wire [16:0] pi_addr;
    reg [7:0] pi_data_in;
    wire [7:0] pi_data_out;
    wire pi_rw_b;
    reg pi_pending_in = 1'b0;
    wire pi_pending_out;
    reg pi_done_in = 1'b0;
    wire pi_done_out;

    pi_com pi_com(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .pi_addr(pi_addr),
        .pi_data_in(pi_data_in),
        .pi_data_out(pi_data_out),
        .pi_rw_b(pi_rw_b),
        .pi_pending_in(pi_pending_in),
        .pi_pending_out(pi_pending_out),
        .pi_done_in(pi_done_in),
        .pi_done_out(pi_done_out)
    );

    task check(
        input pending,
        input rw_b,
        input [16:0] addr,
        input [7:0] data
    );
        $display("[%t]    expect(pending: %d, rw_b: %d, addr: $%x, data: $%x)",
            $time, pi_pending_out, pi_rw_b, pi_addr, pi_data_out);

        assert_equal(pi_pending_out, pending, "pi_pending_out");
        assert_equal(pi_rw_b, rw_b, "pi_rw_b");
        assert_equal(pi_addr, addr, "pi_addr");

        if (!rw_b) begin
            assert_equal(pi_data_out, data, "pi_data_out");
        end else begin
            assert_equal(last_rx_byte, data, "last_rx_byte");
        end

        #500 pi_done_in = 1'b1;        
        @(posedge sys_clk);
        #1 assert_equal(pi_done_out, 1'b1, "pi_done_out");

        #500 pi_pending_in = 1'b0;
        @(posedge sys_clk);
        assert_equal(pi_pending_out, 1'b0, "pi_pending_out");
        assert_equal(pi_done_out, 1'b0, "pi_done_out");

        pi_done_in = 1'b0;
    endtask

    logic unsigned [7:0] bytes [];
    logic unsigned [7:0] cmd;
    logic unsigned [7:0] addr_hi;
    logic unsigned [7:0] addr_lo;

    task write_at(
        input [16:0] addr,
        input [7:0] data
    );
        cmd = { 7'b100_xx_1_0, addr[16] };
        addr_hi = addr[15:8];
        addr_lo = addr[7:0];

        bytes = '{
            cmd,
            addr_hi,
            addr_lo,
            data
        };

        $display("[%t]    write_at($%x, $%x) -> [%%%b, $%x, $%x, $%x]",
            $time,
            addr,
            data,
            bytes[0],
            bytes[1],
            bytes[2],
            bytes[3]);

        #1 pi_pending_in = 1'b1;

        foreach(bytes[i]) begin
            assert_equal(pi_pending_out, 1'b0, "pi_pending_out");

            begin_xfer;
            xfer_byte(bytes[i]);
            end_xfer;
        end

        check(/* pending: */ 1'b1, /* rw_b: */ 1'b0, /* addr: */ addr, /* data: */ data);
    endtask

    task read_at(
        input [16:0] addr,
        input [7:0] data
    );
        pi_data_in <= data;

        cmd = { 7'b011_xx_1_1, addr[16] };
        addr_hi = addr[15:8];
        addr_lo = addr[7:0];

        bytes = '{
            cmd,
            addr_hi,
            addr_lo
        };

        $display("[%t]    read_at($%x) -> [%%%b, $%x, $%x]",
            $time,
            addr,
            bytes[0],
            bytes[1],
            bytes[2]);

        #1 pi_pending_in = 1'b1;

        foreach (bytes[i]) begin
            assert_equal(pi_pending_out, 1'b0, "pi_pending_out");

            begin_xfer;
            xfer_byte(bytes[i]);
            end_xfer;
        end

        check(/* pending: */ 1'b1, /* rw_b: */ 1'b1, /* addr: */ addr, /* data: */ data);
    endtask

    task read_next(
        input [16:0] addr,
        input [7:0] data
    );
        pi_data_in <= data;

        cmd = { 7'b001_xx_1_1, addr[16] };

        bytes = '{
            cmd
        };

        $display("[%t]    read_next($%x) -> [%%%b]",
            $time,
            addr,
            bytes[0]);

        #1 pi_pending_in = 1'b1;

        foreach (bytes[i]) begin
            assert_equal(pi_pending_out, 1'b0, "pi_pending_out");

            begin_xfer;
            xfer_byte(bytes[i]);
            end_xfer;
        end

        check(/* pending: */ 1'b1, /* rw_b: */ 1'b1, /* addr: */ addr, /* data: */ data);
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        write_at(/* addr: */ 17'h8000, /* data: */ 8'h55);
        read_at(/* addr: */ 17'h8000, /* data: */ 8'h55);
        read_next(/* addr: */ 17'h8001, /* data: */ 8'h55);
        write_at(/* addr: */ 17'h8001, /* data: */ 8'h55);
        read_at(/* addr: */ 17'h8001, /* data: */ 8'h55);
        read_next(/* addr: */ 17'h8002, /* data: */ 8'h55);

        #500 $finish;
    end
endmodule
