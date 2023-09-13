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

module spi_driver #(
    parameter SCK_MHZ = 24
)(
    output logic spi_sck_o,
    output logic spi_cs_no,
    input  logic spi_rx_i,
    output logic spi_tx_o
);
    bit start_sck = '0;

    always @(posedge start_sck) begin
        while (start_sck) begin
            #(1000 / SCK_MHZ / 4);
            spi_sck_o <= '1;
            #(1000 / SCK_MHZ / 2);
            spi_sck_o <= '0;
            #(1000 / SCK_MHZ / 4);
        end
    end

    task reset;
        spi_cs_no = '0;
        #1;
        spi_sck_o = '0;
        spi_cs_no = '1;
        #1;
    endtask

    task begin_xfer(
        input byte tx_i
    );
        assert(spi_cs_no == 1'b1) else begin
            $error("begin_xfer(): /CS must not be asserted.");
            $finish;
        end

        // MSB of 'tx_byte' is preloaded while spi_cs_no is high on rising edge of clk_sys.
        tx_byte = tx_i;
        spi_cs_no = '0;
        #1;
        start_sck = '1;
    endtask

    integer bit_index;

    task xfer_bits(
        input logic [7:0] next_tx = 8'hxx,
        input integer num_bits = 8
    );
        for (bit_index = 0; bit_index < num_bits; bit_index++) begin
            @(posedge spi_sck_o);

            // 'tx_byte' is loaded on falling edge of spi_sck_o when the last bit is transfered.
            // However, we update 'tx_byte' after every bit to verify that 'tx_byte' is held
            // between loads.
            tx_byte = next_tx;
        end
    endtask

    task xfer_bytes(
        input logic unsigned [7:0] tx[]
    );
        integer i;
        
        foreach(tx[i]) begin
            // 'next_tx' is the next byte to load on the 8th falling edge of SCK.
            xfer_bits(tx[i + 1]);
        end
    endtask

    task end_xfer(
        input bit next_cs_ni = 1'b1
    );
        assert(spi_cs_no == '0) else begin
            $error("end_xfer(): /CS must be asserted.");
            $finish;
        end

        start_sck = 0;

        #1;
        spi_cs_no = next_cs_ni;

        #1;
    endtask

    task send(
        input logic unsigned [7:0] tx[]
    );
        integer i;
        
        // string s;
        // s = "";
        // foreach (tx[i]) s = { s, $sformatf("%h ", tx[i]) };
        // $display("[%t] SPI Send: [ %s]", $time, s);

        // 'tx_byte' is continuously preloaded from falling edge of CS_N.
        begin_xfer(tx[0]);

        foreach(tx[i]) begin
            // 'next_tx' is the next byte to load on the 8th falling edge of SCK.
            xfer_bits(tx[i + 1]);
        end

        @(negedge spi_sck_o);
        end_xfer();
    endtask

    logic       spi_en;
    logic [7:0] tx_byte = 8'hxx;
    logic [7:0] rx_byte_d, rx_byte_q;

    spi_byte spi_byte_tx(
        .spi_sck_i(spi_sck_o),
        .spi_cs_ni(spi_cs_no),
        .spi_rx_i(spi_rx_i),
        .spi_tx_o(spi_tx_o),
        .tx_byte_i(tx_byte),
        .rx_byte_o(rx_byte_d),
        .en_o(spi_en)
    );

    always_ff @(posedge spi_sck_o) begin
        if (spi_en) rx_byte_q <= rx_byte_d;
    end
endmodule
