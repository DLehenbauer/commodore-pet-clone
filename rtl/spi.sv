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
    input  logic sys_clk,       // FPGA clock

    input  logic spi_cs_n,      // CS_N also functions as an asyncronous reset
    input  logic spi_sclk,      // SCLK must be low before falling edge of CS_N
    input  logic spi_rx,
    inout  logic spi_tx,        // High-Z when CS_N to support multiple peripherals

    output logic [7:0] rx,      // Byte recieved.  Valid on rising edge of 'done'.
    input  logic [7:0] tx,      // Byte to transmit.  Producer must hold while transmitting.

    output logic valid,         // RX valid on rising edge, TX captured on falling edge.

    // Exposed for debugging
    output logic [2:0] bit_index = 3'd7
);
    logic done = 1'b0;

    always_ff @(posedge spi_sclk or posedge spi_cs_n) begin
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
        .clk(sys_clk),
        .din(done),
        .dout(valid)
    );

    logic tx_preload = 1'b1;
    logic tx_bit;

    always_ff @(negedge spi_sclk or posedge spi_cs_n) begin
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
