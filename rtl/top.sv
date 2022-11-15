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

    // TODO: Should be 'inout'
    output wire  spi_tx_io,             // RPi 21 : GPIO 9

    input  logic spi_pending_ni,        // RPi  2 : Pending read/write request from RPi
    output logic spi_done_no,           // RPi  3 : Request completed and pi_data held while still pending.
    input  logic mcu_clk,               // RPi  4 : Clock generated by RPi (no longer used)

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
    output logic cpu_en_no,            // CPU 36 : 1 = High impedance,  0 = enabled (be)
    output logic ram_ce_no,            // RAM 22 : 0 = enabled (ce_b),  1 = High impedance
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
    output logic hsync_o,
    output logic vsync_o,
    output logic video_o,

    // DEBUG
    output logic [7:0] pi_data,
    
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
    logic pi_pending, pi_done;
    assign pi_pending  = !spi_pending_ni;
    assign spi_done_no = !pi_done;

    logic res_n = 1'b0;
    logic irq_n = 1'b1;
    logic nmi_n = 1'b1;

    // Note: RESB, IRQB, and NMIB are open drain / wire-OR (see also *.qsf)
    assign cpu_res_naio = res_n ? 1'bZ : 1'b0;
    assign cpu_irq_nio  = irq_n ? 1'bZ : 1'b0;
    assign cpu_nmi_nio  = nmi_n ? 1'bZ : 1'b0;

    assign P3_LED_D2 = spi_pending_ni;
    assign P7_LED_D4 = spi_done_no;
    assign P9_LED_D5 = cpu_res_naio;
    
    wire clk16;     // 16 MHz clock from PLL
    
    pll pll(
        .inclk0(clk_50_i),
        .c0(clk16)
    );
    
    // Audio
    assign audio_o = cb2_i & diag_i;

    // spi_byte debug_byte(
    //    .spi_cs_n(spi_cs_n),
    //    .spi_sclk(spi_sclk),
    //    .spi_rx(spi_rx),
    //    .rx(pi_data)
    //);

    // assign pi_data[0] = spi_sclk;
    // assign pi_data[1] = spi_cs_n;
    // assign pi_data[2] = spi_rx;
    // assign pi_data[3] = spi_tx;

    logic pi_rw_b;
    logic [16:0] pi_addr;
    logic [7:0] pi_wr_data;          // Incoming data when Pi is writing
    logic [7:0] pi_rd_data;          // Outgoing data when Pi is reading
    logic pi_pending_out;
    logic pi_done_in;

    pi_com pi_com(
        .sys_clk(clk16),
        .spi_sclk(spi_sclk_i),
        .spi_cs_n(spi_cs_ni),
        .spi_rx(spi_rx_i),
        .spi_tx(spi_tx_io),
        .pi_addr(pi_addr),
        .pi_data_in(pi_rd_data),
        .pi_data_out(pi_wr_data),
        .pi_rw_b(pi_rw_b),
        .pi_pending_in(pi_pending),
        .pi_pending_out(pi_pending_out),
        .pi_done_in(pi_done_in),
        .pi_done_out(pi_done),

        // Expose internal state for debugging
        .state(pi_data[2:0]),
        .rx_valid(pi_data[6])
    );
    
    main main(
        .pi_rw_b(pi_rw_b),
        .pi_addr({ 1'b0, pi_addr }),
        .pi_wr_data(pi_wr_data),    // Incoming data when Pi is writing
        .pi_rd_data(pi_rd_data),    // Outgoing data when Pi is reading
        .bus_rw_b(bus_rw_nio),
        .bus_addr(bus_addr_io),
        .bus_data(bus_data_io),
        .ram_addr(ram_addr_o),
        .clk16(clk16),
        .phi2(clk_cpu_o),
        .ram_oe_b(ram_oe_no),
        .ram_we_b(ram_we_no),
        .pi_pending(pi_pending_out),
        .pi_done(pi_done_in),
        .reset_in(!cpu_res_naio),
        .res_b_out(res_n),
        .cpu_rdy(cpu_ready_o),
        .cpu_sync(cpu_sync_i),
        .cpu_be(cpu_en_no),
        .ram_ce_b(ram_ce_no),
        .pia1_cs2_b(pia1_cs2_no),
        .pia2_cs2_b(pia2_cs2_no),
        .via_cs2_b(via_cs2_no),
        .io_oe_b(io_oe_no),
        .gfx(gfx_i),
        .hsync(hsync_o),
        .vsync(vsync_o),
        .video(video_o)
    );
endmodule