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
    input  logic sys_clk,        // FPGA clock

    input  logic spi_cs_n,       // CS_N also functions as a synchronous reset
    input  logic spi_sclk,       // SCLK must be low before falling edge of CS_N
    input  logic spi_rx,
    output logic spi_tx,

    output logic [7:0] rx_byte,  // Byte recieved.  Valid on rising edge of 'valid'.
    input  logic [7:0] tx_byte,  // Byte to transmit.  Loaded on falling edges of CS_N and last SCLK of byte.

    output logic valid = 1'b0    // 'rx_byte' valid pulse is high for one period of sys_clk.
);
    // Signals crossing clock domain
    logic spi_cs_n_d, spi_cs_n_q;
    logic spi_sclk_d, spi_sclk_q;
    logic spi_rx_d, spi_rx_q;
    logic spi_tx_d;

    // Shift register simultaneously clocks in the incoming 'rx' bit at [0] as we clock out
    // the outgoing 'tx' bit at [7].
    logic [7:0] sr_d, sr_q;

    // Counts transferred bits to detect when to copy rx / load tx.
    logic [2:0] bit_count_d, bit_count_q = 3'd0;

    // 'sr' is copied to 'rx_byte' on the rising edge of the 'valid' pulse.
    logic [7:0] rx_byte_d;
    logic valid_d;

    // Detect positive and negative edges of 'spi_sclk_q'.
    logic spi_sclk_d2, spi_sclk_q2;
    logic spi_sclk_pe, spi_sclk_ne;
    assign spi_sclk_pe = !spi_sclk_q2 && spi_sclk_q;
    assign spi_sclk_ne = spi_sclk_q2 && !spi_sclk_q;

    always_comb begin
        // Signals crossing clock domain
        spi_cs_n_d  = spi_cs_n;
        spi_sclk_d  = spi_sclk;
        spi_rx_d    = spi_rx;
        spi_tx_d    = spi_tx;
        
        spi_sclk_d2 = spi_sclk_q;

        sr_d        = sr_q;
        bit_count_d = bit_count_q;
        rx_byte_d   = rx_byte;
        valid_d     = 1'b0;

        if (spi_cs_n_q) begin
            bit_count_d = 3'b0;

            // Reset 'valid' pulse
            valid_d     = 1'b0;

            // Continuously preload 'tx_byte'
            sr_d        = tx_byte;
            spi_tx_d    = tx_byte[7];
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
                    sr_d     = tx_byte;
                    spi_tx_d = tx_byte[7];
                end else begin
                    // Prepare 'spi_tx' with the next outgoing bit of 'tx_byte' so it's available
                    // on the next positive edge SCLK.
                    spi_tx_d = sr_q[7];
                end
            end
        end
    end

    always_ff @(posedge sys_clk) begin
        bit_count_q <= bit_count_d;
        sr_q        <= sr_d;

        spi_cs_n_q  <= spi_cs_n_d;
        spi_sclk_q  <= spi_sclk_d;
        spi_sclk_q2 <= spi_sclk_d2;
        spi_rx_q    <= spi_rx_d;
        spi_tx      <= spi_tx_d;

        rx_byte     <= rx_byte_d;
        valid       <= valid_d;
    end
endmodule
