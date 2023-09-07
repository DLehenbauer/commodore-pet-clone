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

// Implements core of SPI Mode 0 byte transfers in a controller/peripheral agnostic way.
module spi_byte (
    input  logic spi_cs_ni,         // CS_N also functions as an asynchronous reset
    input  logic spi_sck_i,         // SCK must be low before falling edge of CS_N
    input  logic spi_rx_i,
    output logic spi_tx_o,
    
    input  logic [7:0] tx_byte_i,   // Byte transmitted.  Captured on falling edge of CS_N and
                                    // negative edge last falling edge of SCK.

    output logic [7:0] rx_byte_o,   // Received byte shift register contents
    output logic en_o = '0
);
    logic valid_d;
    logic [2:0] bit_count;
    logic [7:0] rx_byte_q;
    logic [7:0] tx_byte;

    always_comb begin
        en_o = bit_count == 3'd7;
    end

    always_latch begin
        if (!spi_sck_i) rx_byte_o <= { rx_byte_q[6:0], spi_rx_i };
    end

    always_ff @(posedge spi_cs_ni or posedge spi_sck_i) begin
        if (spi_cs_ni) begin
            bit_count <= '0;
            rx_byte_q <= 8'hxx;
        end else begin
            rx_byte_q <= rx_byte_o;
            bit_count <= bit_count + 1'b1;
        end
    end

    always_ff @(negedge spi_cs_ni or negedge spi_sck_i) begin
        if (spi_sck_i) begin
            tx_byte  <= tx_byte_i;
            spi_tx_o <= tx_byte_i[7];
        end else begin
            if (bit_count == '0) begin
                tx_byte  <= tx_byte_i;
                spi_tx_o <= tx_byte_i[7];
            end else begin
                tx_byte  <= { tx_byte[6:0], 1'bx };
                spi_tx_o <= tx_byte[6];
            end
        end
    end
endmodule

// Protocol for SPI1 peripheral
module spi1(
    input  logic clk_i,             // Destination clock domain

    input  logic spi_sck_i,         // SCK
    input  logic spi_cs_ni,         // CS: Also serves as a synchronous reset for the SPI FSM
    input  logic spi_rx_i,          // PICO
    output logic spi_tx_o,          // POCI
    
    output logic spi_valid_o
);
    logic [7:0] spi_rx;
    logic [7:0] spi_tx;
    logic       spi_en;

    spi_byte spi_byte(
        .spi_sck_i(spi_sck_i),
        .spi_cs_ni(spi_cs_ni),
        .spi_rx_i(spi_rx_i),
        .spi_tx_o(spi_tx_o),
        .rx_byte_o(spi_rx),
        .tx_byte_i(spi_tx),
        .en_o(spi_en)
    );

    logic spi_valid = '0;

    always_ff @(posedge spi_cs_ni or posedge spi_sck_i) begin
        if (spi_cs_ni) begin
            spi_valid <= '0;
        end else begin
            if (spi_en) begin
                spi_tx <= spi_rx;
                spi_valid <= 1'b1;
            end
        end
    end

    sync2 sync_valid(
        .clk_i(clk_i),
        .data_i(spi_valid),
        .data_o(spi_valid_o)
    );
endmodule