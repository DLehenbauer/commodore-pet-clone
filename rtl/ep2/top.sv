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
    input logic          clk_50_i,        // 50 MHz oscillator

    // System Bus
    inout wire           bus_rw_nio,    // CPU 34          : 0 = CPU writing, 1 = CPU reading
    inout wire   [16:0]  bus_addr_io,   // CPU 9-20, 22-25 : System address bus
    inout wire    [7:0]  bus_data_io,   // CPU 33-26       : System data bus
    
    output logic [11:10] ram_addr_o,    // RAM: Intercept A11/A10 to mirror VRAM.  Must remove zero ohm
                                        //      resistors at R9 and R10.
    // SPI
    input  logic spi_sclk_i,            // RPi 23 : GPIO 11
    input  logic spi_cs_ni,             // RPi 24 : GPIO 8
    input  logic spi_rx_i,              // RPi 19 : GPIO 10
    inout  wire  spi_tx_io,             // RPi 21 : GPIO 9 (High-Z when SPI CS is deasserted)

    output logic spi_ready_no,          // RPi  3 : Request completed and pi_data held while still pending.
    input  logic mcu_clk,               // RPi  4 : Clock generated by MCU (no longer used)

    // Timing
    output logic clk_cpu_o,             // CPU 37 : 1 MHz cpu clock
    output logic ram_oe_no,             // RAM 24 : 0 = output enabled, 1 = High impedance
    output logic ram_we_no,             // RAM 29 : 0 = write enabled,  1 = Not active

    // CPU
    inout  logic cpu_res_naio,          // CPU 40 : 0 = Reset, 1 = Normal [Open drain]
    output logic cpu_ready_o,           // CPU  2 : 0 = Halt,  1 = Run
    inout  wire  cpu_irq_nio,           // CPU  4 : 0 = Interrupt requested, 1 = Normal [Open drain]
    inout  wire  cpu_nmi_nio,           // CPU  6 : 0 = Interrupt requested, 1 = Normal [Open drain]
    input  wire  cpu_sync_i,            // CPU  7 :

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
    output logic video_o,

    // Reserved by DevBoard
    // (See http://land-boards.com/blwiki/index.php?title=Cyclone_II_EP2C5_Mini_Dev_Board#I.2FO_Pin_Mapping)
    output logic P3_LED_D2,           // Low to Light LED
    output logic P7_LED_D4,           // Low to Light LED
    output logic P9_LED_D5,           // Low to Light LED
    input  logic P26_1V2,             // VCC 1.2V for EP2C8.  On EP2C5, remove "Zero ohm" resistor to use pin used as normal.
    input  logic P27_GND,             // GND for EP2C8.  On EP2C5, remove "Zero ohm" resistor to use pin used as normal.
    input  logic P73_POR              // 10uF capacitor to ground + 10K resistor to Vcc (Presumably for power up reset?)
    
    // The following reserved Pins are currently in use:
    //    P17_50MHz - 50 MHz oscillator (clk_50_i)
    //    P80/81    - Removed R9/R10 and used for ram_addr_o[11:10]
    //    P144      - Used for cpu_res_naio
    //
    // input logic  P17_50MHz,           // 50 MHz oscillator
    // input logic  P80_GND,             // GND for EP2C8.  On EP2C5, remove "Zero ohm" resistor to use pin used as normal.
    // input logic  P81_1V2              // VCC 1.2Vfor EP2C8.  On EP2C5, remove "Zero ohm" resistor to use pin used as normal.
    // inout logic P144_KEY              // Push to ground.  Requires internal pullup on FPGA if used.
);
    logic res_n = 1'b0;
    logic irq_n = 1'b1;
    logic nmi_n = 1'b1;

    // Note: RESB, IRQB, and NMIB are open drain / wire-OR (see also *.qsf)
    assign cpu_res_naio = res_n ? 1'bZ : 1'b0;
    assign cpu_irq_nio  = irq_n ? 1'bZ : 1'b0;
    assign cpu_nmi_nio  = nmi_n ? 1'bZ : 1'b0;

    assign P3_LED_D2 = spi_cs_ni;
    assign P7_LED_D4 = spi_ready_no;
    assign P9_LED_D5 = res_n ? cpu_res_naio : 1'b0;
    
    logic clk_16;     // 16 MHz clock from PLL
    
    pll pll(
        .inclk0(clk_50_i),
        .c0(clk_16)
    );
    
    // Audio
    assign audio_o = cb2_i & diag_i;
    
    logic bus_rw_ni;
    logic bus_rw_no;
    logic bus_rw_noe;

    logic [15:0] bus_addr_i;
    logic [16:0] bus_addr_o;
    logic        bus_addr_oe;

    logic  [7:0] bus_data_i;
    logic  [7:0] bus_data_o;
    logic        bus_data_oe;

    logic        spi_tx_o;

    main main(
        .spi_sclk_i(spi_sclk_i),
        .spi_cs_ni(spi_cs_ni),
        .spi_rx_i(spi_rx_i),
        .spi_tx_o(spi_tx_o),
        .spi_ready_no(spi_ready_no),
        .bus_rw_ni(bus_rw_ni),
        .bus_rw_no(bus_rw_no),
        .bus_rw_noe(bus_rw_noe),
        .bus_addr_i(bus_addr_i),
        .bus_addr_o(bus_addr_o),
        .bus_addr_oe(bus_addr_oe),
        .bus_data_i(bus_data_i),
        .bus_data_o(bus_data_o),
        .bus_data_oe(bus_data_oe),
        .ram_addr_o(ram_addr_o),
        .clk_16_i(clk_16),
        .clk_cpu_o(clk_cpu_o),
// Correct:
        .ram_oe_no(ram_oe_no),
        .ram_we_no(ram_we_no),

// Bodge:
//        .ram_oe_no(ram_we_no),
//        .ram_we_no(ram_oe_no),

        .cpu_res_ai(!cpu_res_naio),
        .cpu_res_nao(res_n),
        .cpu_ready_o(cpu_ready_o),
        .cpu_sync_i(cpu_sync_i),
        .cpu_en_o(cpu_en_o),
        .ram_ce_no(ram_ce_no),
        .pia1_cs2_no(pia1_cs2_no),
        .pia2_cs2_no(pia2_cs2_no),
        .via_cs2_no(via_cs2_no),
        .io_oe_no(io_oe_no),
        .gfx_i(gfx_i),
        .h_sync_o(h_sync_o),
        .v_sync_o(v_sync_o),
        .video_o(video_o)
    );

    assign bus_rw_ni  = bus_rw_nio;
    assign bus_rw_nio = bus_rw_noe
        ? bus_rw_no
        : 1'bZ;

    assign bus_addr_i  = bus_addr_io[15:0];
    assign bus_addr_io = bus_addr_oe
        ? bus_addr_o
        : { bus_addr_o[16], 16'bZ };

    assign bus_data_i  = bus_data_io;
    assign bus_data_io = bus_data_oe
        ? bus_data_o
        : 8'bZ;

    // 'spi_tx_io' is high-Z when 'spi_cs_ni' is deasserted to allow other devices to transmit
    assign spi_tx_io = spi_cs_ni
        ? 1'bZ
        : spi_tx_o;
endmodule
