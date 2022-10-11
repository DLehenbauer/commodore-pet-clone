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
    input sys_clk,
    input spi_sclk,
    input spi_cs_n,
    input spi_rx,
    output spi_tx,

    output reg [7:0] rx [4],
    output reg [2:0] rx_count = 0,

    input [7:0] tx_byte,

    output [7:0] rx0,
    output [7:0] rx1,
    output [7:0] rx2,
    output [7:0] rx3
);
    
    wire [7:0] rx_byte;
    wire byte_valid;

    assign rx0 = rx[0];
    assign rx1 = rx[1];
    assign rx2 = rx[2];
    assign rx3 = rx[3];

    spi_byte spi(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx(rx_byte),
        .tx(tx_byte),
        .valid(byte_valid)
    );

    integer i;

    always @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            rx_count <= 0;

            foreach (rx[i]) begin
                rx[i] <= 8'hxx;
            end
        end else if (byte_valid) begin
            rx[rx_count] <= rx_byte;
            rx_count <= rx_count + 1'b1;
        end
    end
endmodule
