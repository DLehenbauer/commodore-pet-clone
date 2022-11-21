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
    input  logic clk_sys_i,         // FPGA clock

    input  logic spi_cs_ni,         // CS_N also functions as a synchronous reset
    input  logic spi_sclk_i,        // SCLK must be low before falling edge of CS_N
    input  logic spi_rx_i,
    output logic spi_tx_o,

    output logic [7:0] rx_byte_o,   // Byte recieved.  Valid on rising edge of 'valid'.
    input  logic [7:0] tx_byte_i,   // Byte to transmit.  Loaded on falling edges of CS_N and last SCLK of byte.

    output logic valid_o = 1'b0     // 'rx_byte' valid pulse is high for one period of clk_sys_i.
);
    // Signals crossing clock domain
    logic spi_cs_nq;
    logic spi_sclk_q;
    logic spi_rx_q;
    logic spi_tx_d;

    // Shift register simultaneously clocks in the incoming 'rx' bit at 'sr[0]' and clocks out
    // the outgoing 'tx' bit at 'sr[7]'.
    logic [7:0] sr_d, sr_q;

    // Counts the number of bits transfered in the current byte.  Used to detect when to copy
    // 'sr' to 'rx_byte', assert 'valid', and load the next 'tx_byte'.
    logic [2:0] bit_count_d, bit_count_q = '0;

    // 'sr' is copied to 'rx_byte' on the rising edge of the 'valid' pulse.
    logic [7:0] rx_byte_d;
    logic valid_d;

    // Detect positive and negative edges of 'spi_sclk_q'.
    logic spi_sclk_q2;
    wire spi_sclk_pe = !spi_sclk_q2 &&  spi_sclk_q;
    wire spi_sclk_ne =  spi_sclk_q2 && !spi_sclk_q;

    always_comb begin
        // Signals crossing clock domain
        spi_tx_d    = spi_tx_o;        
        sr_d        = sr_q;
        bit_count_d = bit_count_q;
        rx_byte_d   = rx_byte_o;
        valid_d     = '0;

        if (spi_cs_nq) begin
            bit_count_d = '0;

            // Reset 'valid' pulse
            valid_d     = '0;

            // Continuously preload 'tx_byte'
            sr_d        = tx_byte_i;
            spi_tx_d    = tx_byte_i[7];
        end else begin
            if (spi_sclk_pe) begin
                // On the positive edge of 'spi_sclk' we shift the incoming 'rx' bit into 'sr'
                // and incement our 'bit_count'.  This simultaneously shifts the next outgoing
                // bit of 'tx_byte' to sr[7].
                sr_d        = { sr_q[6:0], spi_rx_q };
                bit_count_d = bit_count_q + 1'b1;

                if (bit_count_q == 3'd7) begin
                    // We've received the last bit of 'rx_byte'.  Store it in 'rx_byte' and raise
                    // the 'valid' pulse.
                    rx_byte_d = { sr_q[6:0], spi_rx_q };
                    valid_d   = 1'b1;
                end
            end else if (spi_sclk_ne) begin
                if (bit_count_q == 3'd0) begin
                    // We transmitted the last bit of the previous 'tx_byte' on the positive edge
                    // of SCLK.  Load the next value of 'tx_byte' into 'sr' on the negative edge.
                    sr_d     = tx_byte_i;
                    spi_tx_d = tx_byte_i[7];
                end else begin
                    // Prepare 'spi_tx' with the next outgoing bit of 'tx_byte' so it's available
                    // on the next positive edge SCLK.
                    spi_tx_d = sr_q[7];
                end
            end
        end
    end

    always_ff @(posedge clk_sys_i) begin
        bit_count_q <= bit_count_d;
        sr_q        <= sr_d;

        spi_cs_nq   <= spi_cs_ni;
        spi_sclk_q  <= spi_sclk_i;
        spi_sclk_q2 <= spi_sclk_q;
        spi_rx_q    <= spi_rx_i;
        spi_tx_o    <= spi_tx_d;

        rx_byte_o   <= rx_byte_d;
        valid_o     <= valid_d;
    end
endmodule
