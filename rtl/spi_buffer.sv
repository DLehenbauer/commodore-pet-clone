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

module spi_buffer(
    input reset,
    input spi_sclk,
    input spi_cs_n,
    input spi_rx,
    output spi_tx,

    output reg [7:0] rx [4],
    input [2:0] length,
    input [7:0] tx_byte,

    output valid
);
    reg [2:0] count = 0;
    wire [7:0] rx_byte;
    wire byte_valid;

    spi_byte spi(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx(rx_byte),
        .tx(tx_byte),
        .valid(byte_valid)
    );

    always @(posedge byte_valid or posedge reset) begin
        if (reset) begin
            count <= 0;
        end else if (byte_valid) begin
            rx[count] <= rx_byte;
            count <= count + 1'b1;
        end
    end

    assign valid = count == length;
endmodule
