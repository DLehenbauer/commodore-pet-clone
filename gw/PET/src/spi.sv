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
    input  logic spi_cs_ni,         // CS_N also functions as a synchronous reset
    input  logic spi_sck_i,         // SCK must be low before falling edge of CS_N
    input  logic spi_rx_i,
    output logic spi_tx_o,
    
    input  logic [7:0] tx_byte_i,   // Byte transmitted.  Captured on falling edge of CS_N and
                                    // negative edge last falling edge of SCK.

    output logic [7:0] rx_byte_o,   // Byte recieved.  Valid on rising edge of 'valid'.
    output logic rx_valid_o = '0,   // 'rx_byte' valid pulse is high for one period of clk_sys_i.

    output logic reset_o            // Pulse when CS_N deasserts.  Use to reset decoder.
);
    logic valid_d;
    logic [2:0] bit_count;
    logic [7:0] rx_byte_d, rx_byte_q;
    logic [7:0] tx_byte;

    always_comb begin
        rx_byte_d = { rx_byte_q[6:0], spi_rx_i };
        valid_d   = bit_count == 3'd7;
    end

    always_ff @(posedge spi_cs_ni or posedge spi_sck_i) begin
        if (spi_cs_ni) begin
            bit_count <= '0;
            rx_byte_q <= 8'hxx;
        end else begin
            rx_byte_q <= rx_byte_d;
            rx_valid_o <= valid_d;

            if (valid_d) begin
                rx_byte_o  <= rx_byte_d;
            end

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
