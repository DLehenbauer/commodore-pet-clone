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

module spi_byte (
    input  spi_cs_n,        // CS_N also functions as an asyncronous reset
    input  spi_sclk,        // SCLK must be low before falling edge of CS_N
    input  spi_rx,
    output spi_tx,

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Producer must hold while transmitting.

    output valid            // Access rx and update tx while high
);
    reg done = 1'b0;

    always @(posedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            rx <= 8'hxx;
            done <= 1'b0;
        end else if (spi_sclk) begin
            rx <= { rx[6:0], spi_rx };
            done <= tx_bit_index == 3'd0;
        end
    end

    reg [2:0] tx_bit_index = 3'd7;

    always @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            tx_bit_index <= 3'd7;
        end else begin
            tx_bit_index <= tx_bit_index - 1'b1;
        end
    end

    assign valid = done & (tx_bit_index == 3'd7);
    assign spi_tx = tx[tx_bit_index];
endmodule
