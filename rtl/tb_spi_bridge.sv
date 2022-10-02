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
    reg sys_clk;

    initial begin
        sys_clk = 0;
        forever begin
            #31.25 sys_clk = ~sys_clk;
        end
    end

    reg start_sclk = 1'b0;
    reg spi_sclk = 1'b0;

    always @(posedge start_sclk) begin
        while (start_sclk) begin
            spi_sclk = 1'b1;
            #500;
            spi_sclk = 1'b0;
            #500;
        end
    end

    reg spi_cs_n = 1'b1;
    wire spi_rx;
    wire spi_tx;
    wire [7:0] rx_byte;
    reg  [7:0] tx_byte;
    wire spi_valid;

    spi_byte spi_byte_xfer(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .tx(tx_byte),
        .rx(rx_byte),
        .valid(spi_valid)
    );

    reg [7:0] last_rx_byte;

    always @(posedge spi_valid) last_rx_byte <= rx_byte;

    task begin_xfer;
        spi_cs_n = 0;
        #500;
        start_sclk = 1'b1;
    endtask

    task xfer_bit;
        @(posedge spi_sclk);
        @(negedge spi_sclk);
    endtask

    integer bit_index;
    bit expected_valid;

    task xfer(
        input [7:0] data
    );
        $display("[%t]        xfer($%x)", $time, data);
        tx_byte = data;

        for (bit_index = 0; bit_index < 8; bit_index++) begin
            xfer_bit();
        end
    endtask

    task end_xfer;
        start_sclk = 1'b0;
        tx_byte = 8'hxx;

        #500;
        spi_cs_n = 1;

        #500;
    endtask

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

    task write_at(
        input [16:0] addr,
        input [7:0] data
    );
        bytes = '{
            { 7'b100_xx_1_0, addr[16] },
            addr[15:8],
            addr[7:0],
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
            xfer(bytes[i]);
            end_xfer;
        end

        check(/* pending: */ 1'b1, /* rw_b: */ 1'b0, /* addr: */ addr, /* data: */ data);
    endtask

    task read_at(
        input [16:0] addr,
        input [7:0] data
    );
        pi_data_in <= data;

        bytes = '{
            { 7'b011_xx_1_1, addr[16] },
            addr[15:8],
            addr[7:0]
        };

        $display("[%t]    read_at($%x) -> [%b, %x, %x]",
            $time,
            addr,
            data,
            bytes[0],
            bytes[1],
            bytes[2]);

        #1 pi_pending_in = 1'b1;

        foreach(bytes[i]) begin
            assert_equal(pi_pending_out, 1'b0, "pi_pending_out");

            begin_xfer;
            xfer(bytes[i]);
            end_xfer;
        end

        check(/* pending: */ 1'b1, /* rw_b: */ 1'b1, /* addr: */ addr, /* data: */ data);
        
        #500 pi_done_in = 1'b1;
        #500 pi_pending_in = 1'b0;
        #500 pi_done_in = 1'b0;
    endtask

    task read_next(
        input [16:0] addr,
        input [7:0] data
    );
        pi_data_in <= data;

        bytes = '{
            { 7'b001_xx_0_1, addr[16] }
        };

        $display("[%t]    read_next() -> [%b]",
            $time,
            data,
            addr,
            bytes[0]);

        #1 pi_pending_in = 1'b1;

        foreach(bytes[i]) begin
            assert_equal(pi_pending_out, 1'b0, "pi_pending_out");

            begin_xfer;
            xfer(bytes[i]);
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

        #500 $finish;
    end
endmodule
