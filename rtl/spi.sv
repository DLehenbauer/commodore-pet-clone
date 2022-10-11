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
    input  sys_clk,         // FPGA clock

    input  spi_cs_n,        // CS_N also functions as an asyncronous reset
    input  spi_sclk,        // SCLK must be low before falling edge of CS_N
    input  spi_rx,
    inout  spi_tx,          // High-Z when CS_N to support multiple peripherals

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Producer must hold while transmitting.

    output valid            // RX valid on rising edge, TX captured on falling edge.
);
    reg done = 1'b0;
    reg [2:0] bit_index = 3'd7;

    always @(posedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            rx <= 8'hxx;
            done <= 1'b0;
            bit_index <= 3'd7;
        end else if (spi_sclk) begin
            rx <= { rx[6:0], spi_rx };
            done <= bit_index == 3'd0;
            bit_index <= bit_index - 1'b1;
        end
    end

    pe_pulse valid_pulse(
        .reset(spi_cs_n),
        .clk(!sys_clk),
        .din(done),
        .dout(valid)
    );

    reg tx_preload = 1'b1;
    reg tx_bit;

    always @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            tx_preload <= 1'b1;
            tx_bit <= 1'bx;
        end else begin
            tx_preload <= 1'b0;
            tx_bit <= tx[bit_index];
        end
    end

    assign spi_tx = spi_cs_n
        ? 1'bz
        : tx_preload
            ? tx[3'd7]
            : tx_bit;
endmodule
