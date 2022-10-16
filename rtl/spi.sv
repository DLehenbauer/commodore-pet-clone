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
    output logic [2:0] bit_index
);
    logic spi_sclk_q;

    sync2 spi_sclk_sync(
        .reset(spi_cs_n),
        .clk(sys_clk),
        .din(spi_sclk),
        .dout(spi_sclk_q)
    );

    logic spi_sclk_rise;
    logic spi_sclk_fall;

    pulse sclk_pulse(
        .reset(spi_cs_n),
        .clk(sys_clk),
        .din(spi_sclk_q),
        .pe(spi_sclk_rise),
        .ne(spi_sclk_fall)
    );

    logic spi_cs_n_d, spi_cs_n_q = 1'b1;
    logic tx_preload_d, tx_preload_q = 1'b1;
    logic tx_bit_d, tx_bit_q;
    logic [2:0] bit_index_d, bit_index_q = 3'd7;
    logic [7:0] rx_d, rx_q;
    logic done_d, done_q = 1'b0;

    always_comb begin
        spi_cs_n_d      = spi_cs_n;
        rx_d            = rx_q;
        done_d          = done_q;
        bit_index_d     = bit_index_q;
        tx_preload_d    = tx_preload_q;
        tx_bit_d        = tx_bit_q;

        if (spi_cs_n) begin
            rx_d            = 8'hxx;
            done_d          = 1'b0;
            bit_index_d     = 3'd7;
            tx_preload_d    = 1'b1;
            tx_bit_d        = 1'bx;
        end else if (spi_sclk_rise) begin
            rx_d            = { rx_q[6:0], spi_rx };
            done_d          = bit_index_q == 3'd0;
            bit_index_d     = bit_index_q - 1'b1;
        end else if (spi_sclk_fall) begin
            tx_preload_d    = 1'b0;
            tx_bit_d        = tx[bit_index_q];
        end
    end

    always_ff @(posedge sys_clk) begin
        spi_cs_n_q      <= spi_cs_n_d;
        rx_q            <= rx_d;
        done_q          <= done_d;
        bit_index_q     <= bit_index_d;
        tx_preload_q    <= tx_preload_d;
        tx_bit_q        <= tx_bit_d;
    end

    pulse valid_pulse(
        .reset(spi_cs_n_q),
        .clk(sys_clk),
        .din(done_q),
        .pe(valid)
    );

    assign rx = rx_q;
    assign bit_index = bit_index_q;
    assign spi_tx = spi_cs_n
        ? 1'bz
        : tx_preload_q
            ? tx[3'd7]
            : tx_bit_q;
endmodule
