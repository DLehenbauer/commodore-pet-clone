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
    reg  [7:0] tx;
    wire tx_valid;

    spi_byte spi_byte_tx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .tx(tx),
        .valid(tx_valid)
    );

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
        tx = data;

        for (bit_index = 0; bit_index < 8; bit_index++) begin
            xfer_bit();
        end
    endtask

    task end_xfer;
        start_sclk = 1'b0;
        tx = 8'hxx;

        #500;
        spi_cs_n = 1;

        #500;
    endtask

    wire [16:0] pi_addr;
    wire [7:0]  pi_data_out;
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
        .pi_data_out(pi_data_out),
        .pi_rw_b(pi_rw_b),
        .pi_pending_in(pi_pending_in),
        .pi_pending_out(pi_pending_out),
        .pi_done_in(pi_done_in),
        .pi_done_out(pi_done_out)
    );

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 pi_pending_in = 1'b1;

        begin_xfer;
        xfer(8'h40);
        end_xfer;

        begin_xfer;
        xfer(8'h55);
        end_xfer;

        begin_xfer;
        xfer(8'h81);
        end_xfer;
        
        begin_xfer;
        xfer(8'h7e);
        end_xfer;

        assert_equal(pi_pending_out, 1'b1, "pi_pending_out");
        assert_equal(pi_addr, 17'h15581, "pi_addr");
        assert_equal(pi_data_out, 8'h7e, "pi_data_out");
        assert_equal(pi_rw_b, 1'b0, "pi_rw_b");
        
        #500 pi_done_in = 1'b1;
        #500 pi_pending_in = 1'b0;
        #500 pi_done_in = 1'b0;
        #500 $finish;
    end
endmodule
