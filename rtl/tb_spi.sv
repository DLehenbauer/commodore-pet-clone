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
    reg spi_sclk = 1'b0;
    reg spi_cs_n = 1'b1;
    wire spi_rx;
    wire spi_tx;

    wire [7:0] rx;
    reg  [7:0] tx;
    wire rx_valid;
    wire tx_valid;

    reg sys_clk;

    initial begin
        sys_clk = 0;
        forever begin
            #23 sys_clk = ~sys_clk;
        end
    end

    spi_byte spi_byte_rx(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        
        .rx(rx),
        .valid(rx_valid)
    );

    spi_byte spi_byte_tx(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .tx(tx),
        .valid(tx_valid)
    );

    reg [7:0] last_rx;

    always @(posedge rx_valid) begin
        last_rx <= rx;
    end

    task check_valid(
        input expected
    );
        assert_equal(rx_valid, expected, "rx_valid");
        assert_equal(tx_valid, expected, "tx_valid");
    endtask

    always @(posedge spi_sclk) begin
        check_valid(1'b0);
    end

    task begin_xfer;
        spi_cs_n = 0;
        #500;
    endtask

    integer bit_index;
    bit expected_valid;

    task xfer_bit();
        spi_sclk = 1'b1;
        #500;
        spi_sclk = 1'b0;
        #499;

        expected_valid = bit_index == 7;

        $display("[%t]    'valid' must be %d after bit %0d.", $time, expected_valid, bit_index);
        #1 check_valid(expected_valid);
    endtask

    task xfer(
        input [7:0] data,
        input integer num_bits = 8
    );
        tx = data;

        for (bit_index = 0; bit_index < num_bits; bit_index++) begin
            xfer_bit();
        end

        if (num_bits == 8) begin
            $display("[%t]    Must receive byte $%x.", $time, data);
            assert_equal(last_rx, data, "last_rx");
        end else begin
            $display("[%t]    'valid' must 0 after incomplete transfer.", $time);
            #1 check_valid(1'b0);
        end
    endtask

    task end_xfer;
        tx = 1'bx;
        spi_cs_n = 1;

        $display("[%t]    'valid' must be reset by 'cs_n'.", $time);
        #1 check_valid(1'b0);

        #499;
    endtask

    integer i;
    byte values[];

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        $display("[%t] Test: 'valid' must be 0 at power on.", $time);
        #1 check_valid(1'b0);

        $display("[%t] Test: Toggle cs_n after power on.", $time);
        values = new [4];
        values = '{
            8'b11011010,
            8'b01011011
        };

        foreach (values[i]) begin
            $display("[%t] Test: Transfer single byte $%h.", $time, values[i]);
            begin_xfer;
            xfer(/* data: */ values[i]);
            end_xfer;
        end


        $display("[%t] Test: Transfer consecutive bytes $%h $%h.", $time, values[0], values[1]);
        begin_xfer;
        foreach (values[i]) begin
            xfer(/* data: */ values[i]);
        end
        end_xfer;

        for (i = 0; i < 8; i++) begin
            $display("[%t] Test: Toggling cs_n after %d bits resets spi state.", $time, i);
            begin_xfer;
            xfer(/* data: */ values[0], /* num_bits: */ i);
            end_xfer;

            $display("[%t] Test: Transfers correctly after toggling cs_n.", $time);
            begin_xfer();
            xfer(/* data: */ values[0]);
            end_xfer();
        end

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
