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
    input  sys_clk,         // FPGA system clock.  Must be >= 4x spi_sclk.

    input  spi_cs_n,        // CS_N also functions as an asyncronous reset
    input  spi_sclk,        // SCLK must be low before falling edge of CS_N
    input  spi_rx,
    output spi_tx,

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Producer must latch while transmitting.

    output valid            // Should copy/access rx and update tx on rising edge.
);
    always @(posedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            rx <= 8'hxx;
        end else if (spi_sclk) begin
            rx <= { rx[6:0], spi_rx };
        end
    end

    reg done = 1'b0;
    reg [2:0] tx_bit_index = 3'd7;

    always @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            done <= 1'b0;
            tx_bit_index <= 3'd7;
        end else begin
            done <= tx_bit_index == 3'd0;
            tx_bit_index <= tx_bit_index - 1'b1;
        end
    end

    assign spi_tx = tx[tx_bit_index];

    reg done_2 = 1'b0;
    reg done_3 = 1'b0;

    always @(negedge sys_clk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            done_3 <= 1'b0;
            done_2 <= 1'b0;
        end else begin
            done_3 <= done_2;
            done_2 <= done;
        end
    end

    assign valid = ~done_3 & done_2;
endmodule
