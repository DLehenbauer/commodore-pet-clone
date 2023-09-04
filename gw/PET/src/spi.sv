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

 module edge_detect(
    input logic clk_i,      // Sampling clock
    input logic data_i,     // Input signal to detect edges
    output logic pe_o,      // Output for rising edge detection
    output logic ne_o       // Output for falling edge detection
);
    logic [1:0] data = '0;

    always @(posedge clk_i) begin
        pe_o <= ( data[0] && !data[1]);
        ne_o <= (!data[0] &&  data[1]);
        data <= { data[0], data_i };
    end
endmodule

// Implements core of SPI Mode 0 byte transfers in a controller/peripheral agnostic way.
module spi_byte (
    input  logic clk_sys_i,         // Sampling clock.  Should be at least 4x SCK.
    
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
    logic sck_pe, sck_ne;

    edge_detect edge_sck(
        .clk_i(clk_sys_i),
        .data_i(spi_sck_i),
        .pe_o(sck_pe),
        .ne_o(sck_ne)
    );

    logic cs_n_pe, cs_n_ne;

    edge_detect edge_cs_n(
        .clk_i(clk_sys_i),
        .data_i(spi_cs_ni),
        .pe_o(reset_o),
        .ne_o(cs_n_ne)
    );

    logic [2:0] bit_count;
    logic [7:0] tx_byte;

    always_ff @(posedge clk_sys_i) begin
        if (cs_n_ne) begin
            bit_count <= '0;
            tx_byte <= tx_byte_i;
            spi_tx_o <= tx_byte_i[7];
        end else if (sck_pe) begin
            rx_byte_o <= { rx_byte_o[6:0], spi_rx_i };
            bit_count <= bit_count + 1'b1;
        end else if (sck_ne) begin
            if (bit_count == '0) begin
                tx_byte  <= tx_byte_i;
                spi_tx_o <= tx_byte_i[7];
            end else begin
                tx_byte  <= { tx_byte[6:0], 1'bx };
                spi_tx_o <= tx_byte[6];
            end
        end

        rx_valid_o <= sck_pe && bit_count == 4'd7;
    end
endmodule
