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

    wire [7:0] rx;
    reg  [7:0] tx;
    wire rx_valid;
    wire tx_valid;

    spi_byte spi_byte_tx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_tx),
        .spi_tx(spi_rx),
        .tx(tx),
        .valid(tx_valid)
    );

    spi_byte spi_byte_rx(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx(rx),
        .valid(rx_valid)
    );

    task check_valid(
        input expected
    );
        assert_equal(rx_valid, expected, "rx_valid");
        assert_equal(tx_valid, expected, "tx_valid");
    endtask

    always @(posedge spi_sclk) begin
        $display("[%t]    'valid' must be 0 after rising edge of SCLK.", $time);
        while (spi_sclk) begin
            #1 check_valid(1'b0);
        end
    end

    always @(negedge spi_sclk) begin
        $display("[%t]    Completed bit %0d:", $time, bit_index);
        $display("[%t]        'valid' must be 0 at falling edge of SCLK.", $time);
        check_valid(0);

        expected_valid = bit_index === 7;
        $display("[%t]        'valid' must be %d after falling edge of SCLK.", $time, expected_valid);

        #1 check_valid(expected_valid);
    end

    always @(negedge spi_cs_n) begin
        $display("[%t]    'valid' must be reset by 'cs_n'.", $time);
        #1 check_valid(1'b0);
    end

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
        input [7:0] data,
        input integer num_bits = 8
    );
        tx = data;

        for (bit_index = 0; bit_index < num_bits; bit_index++) begin
            xfer_bit();
        end

        if (num_bits == 8) begin
            $display("[%t]    Must receive byte $%x.", $time, data);
            assert_equal(spi_sclk, 0, "spi_sclk");
            @(posedge rx_valid);
            assert_equal(rx, data, "rx");
            assert_equal(spi_sclk, 0, "spi_sclk");
        end
    endtask

    task end_xfer;
        start_sclk = 0;
        tx = 8'hxx;

        #500;
        spi_cs_n = 1;

        #500;
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
            $display("[%t] Test: Toggling cs_n after %0d bits resets spi state.", $time, i);
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
