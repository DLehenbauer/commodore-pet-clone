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

module top(
    // FPGA
    input  logic         clk_16_i,      // 16 MHz system clock (from PLL)

    // System Bus
    input  logic         bus_rw_ni,     // CPU 34 : 0 = writing, 1 = reading
    output logic         bus_rw_no,     // 
    output logic         bus_rw_noe,    //

    input  logic [15:0]  bus_addr_i,    // CPU 9-20, 22-25 : System address bus
    output logic [16:0]  bus_addr_o,    //
    output logic         bus_addr_oe,   //

    input  logic  [7:0]  bus_data_i,    // CPU 33-26 : System data bus
    output logic  [7:0]  bus_data_o,    //
    output logic         bus_data_oe,   //
    
    output logic [11:10] ram_addr_o,    // RAM: Intercept A11/A10 to mirror VRAM.
    
    // SPI
    input  logic spi_sclk_i,            // RPi 23 : GPIO 11
    input  logic spi_cs_ni,             // RPi 24 : GPIO 8
    input  logic spi_rx_i,              // RPi 19 : GPIO 10
    output logic spi_tx_o,              // RPi 21 : GPIO 9 (Should be High-Z when CS is deasserted)

    output logic spi_ready_no,          // RPi  3 : Request completed and pi_data held while still pending.

    // Timing
    output logic clk_cpu_o,             // CPU 37 : 1 MHz cpu clock
    output logic ram_oe_no,             // RAM 24 : 0 = output enabled, 1 = High impedance
    output logic ram_we_no,             // RAM 29 : 0 = write enabled,  1 = Not active

    // CPU
    input  logic cpu_res_nai,           // CPU 40 : 0 = Reset, 1 = Normal [Open drain]
    output logic cpu_res_nao,           //
    output logic cpu_res_naoe,          //
    
    output logic cpu_ready_o,           // CPU  2 : 0 = Halt,  1 = Run
    
    input  logic cpu_irq_ni,            // CPU  4 : 0 = Interrupt requested, 1 = Normal [Open drain]
    output logic cpu_irq_no,            //
    output logic cpu_irq_noe,           //

    input  logic cpu_nmi_ni,            // CPU  6 : 0 = Interrupt requested, 1 = Normal [Open drain]
    output logic cpu_nmi_no,            //
    output logic cpu_nmi_noe,           //

    input  logic cpu_sync_i,            // CPU  7 :

    // Address Decoding
    output logic cpu_en_o,              // CPU 36 (BE)   : 0 = High impedance, 1 = Enabled
    output logic ram_ce_no,             // RAM 22 (CE_B) : 0 = Enabled, 1 = High impedance
    output logic pia1_cs2_no,
    output logic pia2_cs2_no,
    output logic via_cs2_no,
    output logic io_oe_no,

    // Audio
    input  logic diag_i,
    input  logic cb2_i,
    output logic audio_o,

    // Graphics
    input  logic gfx_i,
    output logic h_sync_o,
    output logic v_sync_o,
    output logic video_o
);
    // Stub to unblock PnR
    always @(posedge clk_16_i) begin
        clk_cpu_o = !clk_cpu_o;
    end
endmodule
