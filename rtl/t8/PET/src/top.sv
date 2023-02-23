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
    input  logic         clk16_i,           // 16 MHz system clock (from PLL)
    output logic         status_no,

    // SPI1
    input  logic spi1_sck_i,                // MCU 14: incoming SCK
    input  logic spi1_cs_ni,                // MCU 13: incoming CS_N
    input  logic spi1_mcu_tx_i,             // MCU 15: incoming from MCU TX
    output logic spi1_mcu_rx_o,             // MCU 12: outgoing to MCU RX
    output logic spi1_mcu_rx_oe,            //         (only drive RX when CS_N asserted)
    output logic spi_ready_no,              // MCU 10: Asserted when previous SPI command completes

    // System Bus
    input  logic [15:0]  bus_addr_15_0_i,   // CPU 9-20, 22-25 : System address bus
    output logic [15:0]  bus_addr_15_0_o,   //
    output logic [15:0]  bus_addr_15_0_oe,  //
    output logic         bus_addr_16_o,     // CPU has 16b bus, therefore A[16] is output only.

    input  logic  [7:0]  bus_data_7_0_i,    // CPU 33-26 : System data bus
    output logic  [7:0]  bus_data_7_0_o,    //
    output logic  [7:0]  bus_data_7_0_oe,   //

    input  logic         bus_rw_ni,         // CPU 34 : 0 = writing, 1 = reading
    output logic         bus_rw_no,         // 
    output logic         bus_rw_noe,        //

    // CPU
    output logic cpu_clk_o,                 // CPU 37 : 1 MHz cpu clock

    input  logic cpu_res_nai,               // CPU 40 : 0 = Reset, 1 = Normal [Open drain]
    output logic cpu_res_nao,               //
    output logic cpu_res_naoe,              //
    
    output logic cpu_ready_o,               // CPU  2 : 0 = Halt,  1 = Run
    
    input  logic cpu_irq_ni,                // CPU  4 : 0 = Interrupt requested, 1 = Normal [Open drain]
    output logic cpu_irq_no,                //
    output logic cpu_irq_noe,               //

    input  logic cpu_nmi_ni,                // CPU  6 : 0 = Interrupt requested, 1 = Normal [Open drain]
    output logic cpu_nmi_no,                //
    output logic cpu_nmi_noe,               //

    output logic cpu_be_o,                  // CPU 36 (BE)   : 0 = High impedance, 1 = Enabled

    // RAM
    output logic ram_ce_no,                 // RAM 22 (CE_B) : 0 = Enabled, 1 = High impedance
    output logic ram_oe_no,                 // RAM 24 : 0 = output enabled, 1 = High impedance
    output logic ram_we_no,                 // RAM 29 : 0 = write enabled,  1 = Not active
    output logic [11:10] ram_addr_o,        // RAM: Intercept A[11:10] to mirror VRAM.   

    // I/O
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
    // Turn off NSTATUS LED to indicate programming has successfully completed.
    assign status_no = 1'b0;

    // Efinity Interface Designer generates a separate output enable for each bus signal.
    // Create a combined logic signal to control OE for bus_addr_o[15:0].  Note that the
    // 6502 is a 16b bus, so the 17th bit (A16) is always an output.
    logic bus_addr_oe;

    assign bus_addr_15_0_oe = {
        bus_addr_oe, bus_addr_oe, bus_addr_oe, bus_addr_oe,
        bus_addr_oe, bus_addr_oe, bus_addr_oe, bus_addr_oe,
        bus_addr_oe, bus_addr_oe, bus_addr_oe, bus_addr_oe,
        bus_addr_oe, bus_addr_oe, bus_addr_oe, bus_addr_oe
    };

    // Efinity Interface Designer generates a separate output enable for each bus signal.
    // Create a combined logic signal to control OE for bus_data_o[7:0].
    logic bus_data_oe;
    
    assign bus_data_7_0_oe = {
        bus_data_oe, bus_data_oe, bus_data_oe, bus_data_oe,
        bus_data_oe, bus_data_oe, bus_data_oe, bus_data_oe
    };

    main main(
        .clk16_i(clk16_i),
        .bus_rw_ni(bus_rw_ni),
        .bus_rw_no(bus_rw_no),
        .bus_rw_noe(bus_rw_noe),
        .bus_addr_i(bus_addr_15_0_i),
        .bus_addr_o({bus_addr_16_o, bus_addr_15_0_o}),
        .bus_addr_oe(bus_addr_oe),
        .bus_data_i(bus_data_7_0_i),
        .bus_data_o(bus_data_7_0_o),
        .bus_data_oe(bus_data_oe),
        .ram_addr_o(ram_addr_o),
        .spi1_sck_i(spi1_sck_i),
        .spi1_cs_ni(spi1_cs_ni),
        .spi1_mcu_tx_i(spi1_mcu_tx_i),
        .spi1_mcu_rx_o(spi1_mcu_rx_o),
        .spi1_mcu_rx_oe(spi1_mcu_rx_oe),
        .spi_ready_no(spi_ready_no),
        .cpu_clk_o(cpu_clk_o),
        .ram_oe_no(ram_oe_no),
        .ram_we_no(ram_we_no),
        .cpu_res_nai(cpu_res_nai),
        .cpu_res_nao(cpu_res_nao),
        .cpu_res_naoe(cpu_res_naoe),
        .cpu_ready_o(cpu_ready_o),
        .cpu_irq_ni(cpu_irq_ni),
        .cpu_irq_no(cpu_irq_no),
        .cpu_irq_noe(cpu_irq_noe),
        .cpu_nmi_ni(cpu_nmi_ni),
        .cpu_nmi_no(cpu_nmi_no),
        .cpu_nmi_noe(cpu_nmi_noe),
        .cpu_be_o(cpu_be_o),
        .ram_ce_no(ram_ce_no),
        .pia1_cs2_no(pia1_cs2_no),
        .pia2_cs2_no(pia2_cs2_no),
        .via_cs2_no(via_cs2_no),
        .io_oe_no(io_oe_no),
        .diag_i(diag_i),
        .cb2_i(cb2_i),
        .audio_o(audio_o),
        .gfx_i(gfx_i),
        .h_sync_o(h_sync_o),
        .v_sync_o(v_sync_o),
        .video_o(video_o)
    );
endmodule
