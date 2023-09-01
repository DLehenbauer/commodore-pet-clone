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
    
    input  logic cpu_ready_i,               // CPU  2 (RDY)  : 0 = Halt, 1 = Run [Open drain]
    output logic cpu_ready_o,               //
    output logic cpu_ready_oe,              //
    
    input  logic cpu_irq_ni,                // CPU  4 (IRQB) : 0 = Interrupt requested, 1 = Normal [Open drain]
    output logic cpu_irq_no,                //
    output logic cpu_irq_noe,               //

    input  logic cpu_nmi_ni,                // CPU  6 (NMIB) : 0 = Interrupt requested, 1 = Normal [Open drain]
    output logic cpu_nmi_no,                //
    output logic cpu_nmi_noe,               //

    output logic cpu_be_o,                  // CPU 36 (BE)   : 0 = High-Z, 1 = Bus Enabled

    // RAM
    output logic ram_oe_no,                 // RAM 24 (OE)   : 0 = Output enabled, 1 = High-z
    output logic ram_we_no,                 // RAM 29 (WE)   : 0 = Write enabled,  1 = Read enabled
    output logic [11:10] ram_addr_11_10_o,  // RAM (A10-A11) : Intercept to mirror VRAM
    output logic [16:15] ram_addr_16_15_o,  // RAM (A15-A16) : Intercept for bank switching

    // I/O
    output logic pia1_cs2_no,               // PIA1 23 (CS2B) : Chip Select (0 = Select, 1 = High-Z)
    output logic pia2_cs2_no,               // PIA2 23 (CS2B) : Chip Select (0 = Select, 1 = High-Z)
    output logic via_cs2_no,                // VIA  23 (CS2B) : Chip Select (0 = Select, 1 = High-Z)
    output logic io_oe_no,

    // Audio
    input  logic diag_i,                    // PIA1  9 (PA7) / USER 5 (DIAG) : 0 = Diag / No Sound, 1 = Normal / Sound
    input  logic via_cb2_i,                 // VIA  19 (CB2) / USER M (CB2)  : Interupt / Handshake (produces squarewave tone)
    output logic audio_o,                   // ΣΔ modulated 1-bit audio output

    // Graphics
    input  logic gfx_i,                     // VIA 39 (CA2) / USER 11 (GRAPHICS) : 0 = Graphics, 1 = Business Character Set
    output logic h_sync_o,
    output logic v_sync_o,
    output logic video_o
);
    // 'status_no' is connected to the NSTATUS LED (0 = on, 1 = off).  The 'status_no'
    // output is assigned to the FPGA's NSTATUS pin, which is is driven low by the by
    // the FPGA if programming fails.  (See AN 006: Configuring Trion FPGAs.)
    //
    // After programming succeeds, 'status_no' is a standard GPIO.  We assign assigned
    // 'status_no' to '!cpu_res_i'.  Because the FPGA's initial state asserts 'cpu_res_i',
    // this will also light the LED if programming succeeds, but the MCU does is unable
    // to communicate with the FPGA.
    //
    // Under normal conditions, the user will see:
    //
    //   - No LEDS while programming is in progress.
    //   - CDONE lights indicating programming.
    //   - NSTATUS blinks briefly, indicating the MCU has reset the 6502.
    //
    assign status_no = !cpu_res_i;

    // Efinity Interface Designer generates a separate output enable for each bus signal.
    // Create a combined logic signal to control OE for bus_addr_o[15:0].  Note that the
    // 6502 is a 16b bus, so the 17th bit (bus_addr_o[16]) is always an output.
    logic bus_addr_oe;

    assign bus_addr_15_0_oe = {
        bus_addr_oe, bus_addr_oe, bus_addr_oe, bus_addr_oe,
        bus_addr_oe, bus_addr_oe, bus_addr_oe, bus_addr_oe,
        bus_addr_oe, bus_addr_oe, bus_addr_oe, bus_addr_oe,
        bus_addr_oe, bus_addr_oe, bus_addr_oe, bus_addr_oe
    };

    // TODO: Implement bank switching.  For now, we echo A15 to R15.
    assign ram_addr_16_15_o[15] = bus_addr_oe
        ? bus_addr_15_0_o[15]
        : bus_addr_15_0_i[15];

    // Efinity Interface Designer generates a separate output enable for each bus signal.
    // Create a combined logic signal to control OE for bus_data_o[7:0].
    logic bus_data_oe;
    
    assign bus_data_7_0_oe = {
        bus_data_oe, bus_data_oe, bus_data_oe, bus_data_oe,
        bus_data_oe, bus_data_oe, bus_data_oe, bus_data_oe
    };

    // For convenience, convert control/reset signals to active high for consistency and
    // to avoid thinking in double negatives.
    logic io_oe_o, pia1_cs_o, pia2_cs_o, via_cs_o,
          ram_ce_o, ram_oe_o, ram_we_o, spi_ready_o;

    assign io_oe_no     = !io_oe_o;
    assign pia1_cs2_no  = !pia1_cs_o;
    assign pia2_cs2_no  = !pia2_cs_o;
    assign via_cs2_no   = !via_cs_o;
    assign ram_oe_no    = !ram_oe_o;
    assign ram_we_no    = !ram_we_o;
    assign spi_ready_no = !spi_ready_o;

    // RES, IRQ, and NMI are active low open drain wired-or signals.  For consistency
    // and convenience we convert these to active high outputs and handle OE here.
    logic cpu_res_i, cpu_res_o;
    assign cpu_res_i   = !cpu_res_ni;
    assign cpu_res_no  = !cpu_res_o;
    assign cpu_res_noe = cpu_res_o;     // Only drive wired-or when asserting RES

    logic cpu_irq_i, cpu_irq_o;
    assign cpu_irq_i   = !cpu_irq_ni;
    assign cpu_irq_no  = !cpu_irq_o;
    assign cpu_irq_noe = cpu_irq_o;     // Only drive wired-or when asserting IRQ

    logic cpu_nmi_i, cpu_nmi_o;
    assign cpu_nmi_i   = !cpu_nmi_ni;
    assign cpu_nmi_no  = !cpu_nmi_o;
    assign cpu_nmi_noe = cpu_nmi_o;     // Only drive wired-or when asserting NMI

    // RDY is an active high wired-or signal with external pullup.  The WAI instruction
    // pulls RDY low while waiting for an interrupt.  The FPGA can also pull RDY low
    // to halt the CPU.
    assign cpu_ready_oe = !cpu_ready_o; // Only drive wired-or when asserting "not ready"

    // IRQ and NMI are currently unused.  Deassert them so they don't drive pins.
    assign cpu_irq_o = '0;
    assign cpu_nmi_o = '0;

    // Only drive POCI (FPGA TX -> MCU RX) when this SPI peripheral is selected
    assign spi1_mcu_rx_oe = !spi1_cs_ni;

    main main(
        .clk_sys_i(clk_sys_i),
        .bus_rw_ni(bus_rw_ni),
        .bus_rw_no(bus_rw_no),
        .bus_rw_noe(bus_rw_noe),
        .bus_addr_i(bus_addr_15_0_i),
        .bus_addr_o({ ram_addr_16_15_o[16], bus_addr_15_0_o }),
        .bus_addr_oe(bus_addr_oe),
        .bus_data_i(bus_data_7_0_i),
        .bus_data_o(bus_data_7_0_o),
        .bus_data_oe(bus_data_oe),
        .ram_addr_o(ram_addr_11_10_o),
        .spi1_sck_i(spi1_sck_i),
        .spi1_cs_ni(spi1_cs_ni),
        .spi1_rx_i(spi1_mcu_tx_i),  // PICO: MCU TX -> FPGA RX
        .spi1_tx_o(spi1_mcu_rx_o),  // POCI: FPGA TX -> MCU RX
        .spi_ready_o(spi_ready_o),
        .cpu_clk_o(cpu_clk_o),
        .ram_oe_o(ram_oe_o),
        .ram_we_o(ram_we_o),
        .cpu_res_i(cpu_res_i),
        .cpu_res_o(cpu_res_o),
        .cpu_ready_o(cpu_ready_o),
        .cpu_be_o(cpu_be_o),
        .pia1_cs_o(pia1_cs_o),
        .pia2_cs_o(pia2_cs_o),
        .via_cs_o(via_cs_o),
        .io_oe_o(io_oe_o),
        .diag_i(diag_i),
        .via_cb2_i(via_cb2_i),
        .audio_o(audio_o),
        .gfx_i(gfx_i),
        .h_sync_o(h_sync_o),
        .v_sync_o(v_sync_o),
        .video_o(video_o)
    );
endmodule
