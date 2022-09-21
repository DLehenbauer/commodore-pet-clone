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
    input  spi_cs_n,        // CS_N also doubles as an asyncronous reset
    input  spi_sclk,        // SCLK must be low before falling edge of CS_N
    input  spi_rx,
    output spi_tx,

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Producer must latch while transmitting.

    output valid            // Should copy/access rx and update tx on rising edge.
);
    reg [2:0] rx_bit_index = 3'd7;
    reg rx_done = 1'b0;

    always @(posedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            rx_bit_index <= 3'd7;
            rx_done <= 1'b0;
            rx <= 8'd0;
        end else if (spi_sclk) begin
            rx[rx_bit_index] <= spi_rx;
            rx_bit_index <= rx_bit_index - 1'b1;
            rx_done <= rx_bit_index == 3'd0;
        end
    end

    reg [2:0] tx_bit_index = 3'd7;
    reg tx_done = 1'b0;

    always @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            tx_done <= 1'b0;
            tx_bit_index <= 3'd7;
        end else begin
            tx_done <= rx_done;
            tx_bit_index <= rx_bit_index;
        end
    end

    assign spi_tx = tx[tx_bit_index];
    assign valid  = rx_done & tx_done;
endmodule