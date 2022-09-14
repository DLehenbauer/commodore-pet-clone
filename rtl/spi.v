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
    input  spi_sclk,
    input  spi_cs_n,        // SPI chip select also doubles as an asyncronous reset
    input  spi_rx,
    output spi_tx,

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Producer must latch while transmitting.

    output reg done = 1
);
    always @(posedge spi_sclk) begin
        if (!spi_cs_n) begin
            rx <= { rx[6:0], spi_rx };
        end
    end

    reg [2:0] tx_bit_index = 3'd7;

    always @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            tx_bit_index <= 7;
            done <= 0;
        end else begin
            tx_bit_index <= tx_bit_index - 1'b1;
            done <= tx_bit_index == 3'd0;
        end
    end

    assign spi_tx = tx[tx_bit_index];
endmodule

module spi_buffer(
    input spi_sclk,
    input spi_cs_n,
    input spi_rx,
    output spi_tx,

    output reg [7:0] rx [4],
    input      [7:0] tx [4],
    input      [2:0] length,

    output done
);
    reg [2:0] count = 0;
    wire [7:0] rx_byte;
    wire [7:0] tx_byte = tx[count];
    wire byte_done;

    spi_byte spi(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx(rx_byte),
        .tx(tx_byte),
        .done(byte_done)
    );

    always @(posedge byte_done or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            count <= 1'b0;
        end else begin
            rx[count] <= rx_byte;
            count <= count + 1'b1;
        end
    end

    assign done = !spi_cs_n && count == length;
endmodule
