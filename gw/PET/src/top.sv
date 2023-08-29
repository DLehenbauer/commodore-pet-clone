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
    input  logic         clk_sys_i,         // 64 MHz clock (from PLL)
    output logic         status_no,         // NSTATUS LED (0 = On, 1 = Off)

    // SPI1
    input  logic spi1_sck_i,                // MCU 17: Incoming SCK
    input  logic spi1_cs_ni,                // MCU 16: Incoming CS_N
    input  logic spi1_mcu_tx_i,             // MCU 14: Incoming MCU TX -> FPGA RX
    output logic spi1_mcu_rx_o,             // MCU 15: Outgoing MCU RX -> FPGA TX
    output logic spi1_mcu_rx_oe,            //         (only drive when CS_N asserted)
    output logic spi_ready_no,              // MCU 13: Assert SPI command completes

    // System Bus
    input  logic [15:0]  bus_addr_15_0_i,   // CPU 9-20, 22-25 (A0-A15) : Address bus
    output logic [15:0]  bus_addr_15_0_o,   //
    output logic [15:0]  bus_addr_15_0_oe,  //

    input  logic  [7:0]  bus_data_7_0_i,    // CPU 33-26 (D0-D7) : Data bus
    output logic  [7:0]  bus_data_7_0_o,    //
    output logic  [7:0]  bus_data_7_0_oe,   //

    input  logic         bus_rw_ni,         // CPU 34 (RWB)  : 0 = writing, 1 = reading
    output logic         bus_rw_no,         // 
    output logic         bus_rw_noe,        //

    // CPU
    output logic cpu_clk_o,                 // CPU 37 (Φ2)   : 1 MHz cpu clock

    input  logic cpu_res_ni,                // CPU 40 (RESB) : 0 = Reset, 1 = Normal [Open drain]
    output logic cpu_res_no,                //
    output logic cpu_res_noe,               //
    
    output logic cpu_ready_o,               // CPU  2 (RDY)  : 0 = Halt, 1 = Run [Bidirectional]
    
    input  logic cpu_irq_ni,                // CPU  4 (IRQB) : 0 = Interrupt requested, 1 = Normal [Open drain]
    output logic cpu_irq_no,                //
    output logic cpu_irq_noe,               //

    input  logic cpu_nmi_ni,                // CPU  6 (NMIB) : 0 = Interrupt requested, 1 = Normal [Open drain]
    output logic cpu_nmi_no,                //
    output logic cpu_nmi_noe,               //

    output logic cpu_be_o,                  // CPU 36 (BE)   : 0 = High-Z, 1 = Bus Enabled

    // RAM
    output logic ram_oe_no,                 // RAM 24 : 0 = output enabled, 1 = High impedance
    output logic ram_we_no,                 // RAM 29 : 0 = write enabled,  1 = Not active
    output logic [11:10] ram_addr_11_10_o,  // RAM (A10-A11): Intercept to mirror VRAM
    output logic [16:15] ram_addr_16_15_o,  // RAM (A15-A16): Intercept for bank switching

    // I/O
    output logic pia1_cs2_no,
    output logic pia2_cs2_no,
    output logic via_cs2_no,
    output logic io_oe_no,

    // Audio
    input  logic diag_i,
    input  logic via_cb2_i,
    output logic audio_o,

    // Graphics
    input  logic gfx_i,
    output logic h_sync_o,
    output logic v_sync_o,
    output logic video_o
);
    timing timing(
        .clk_sys_i(clk_sys_i)
    );
endmodule
