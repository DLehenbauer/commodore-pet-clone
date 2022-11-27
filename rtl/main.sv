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

module main (
    // System Bus
    inout  wire          bus_rw_nio,    // CPU 34          : 0 = CPU writing, 1 = CPU reading
    inout  wire  [16:0]  bus_addr_io,   // CPU 9-20, 22-25 : System address bus
    inout  wire   [7:0]  bus_data_io,   // CPU 33-26       : System data bus
    
    output logic [11:10] ram_addr_o,    // RAM: Intercept A11/A10 to mirror VRAM.  Must remove zero ohm
                                        //      resistors at R9 and R10.

    // SPI
    input  logic spi_sclk_i,            // RPi 23 : GPIO 11
    input  logic spi_cs_ni,             // RPi 24 : GPIO 8
    input  logic spi_rx_i,              // RPi 19 : GPIO 10

    // TODO: Should be 'inout'
    output wire  spi_tx_io,             // RPi 21 : GPIO 9

    output logic spi_ready_no,          // RPi  3 : Request completed and pi_data held while still pending.

    // Timing
    input  logic clk_16_i,              // 16 MHz main clock
    output logic clk_cpu_o,             // CPU 37 : 1 MHz cpu clock
    output logic ram_oe_no,             // RAM 24 : 0 = output enabled, 1 = High impedance
    output logic ram_we_no,             // RAM 29 : 0 = write enabled,  1 = Not active

    // CPU
    input  logic cpu_res_ai,
    output logic cpu_res_nao,
    output logic cpu_ready_o,           // CPU  2 : 0 = halt,  1 = run
    input  logic cpu_sync_i,

    // Address Decoding
    output logic cpu_en_o,              // CPU 36 (BE)   : 0 = High impedance, 1 = Enabled
    output logic ram_ce_no,             // RAM 22 (CE_B) : 0 = Enabled, 1 = High impedance
    output logic pia1_cs2_no,
    output logic pia2_cs2_no,
    output logic via_cs2_no,
    output logic io_oe_no,

    // Video
    input  logic gfx_i,
    output logic h_sync_o,
    output logic v_sync_o,
    output logic video_o,

    output logic [7:0] debug_o
);
    logic spi_ready_out;
    assign spi_ready_no = !spi_ready_out;

    logic        spi_rw_n;
    logic [16:0] spi_addr;
    logic  [7:0] spi_wr_data;   // Incoming data when Pi is writing
    logic  [7:0] spi_rd_data;   // Outgoing data when Pi is reading
    logic        spi_valid;     // Command pending: spi_addr, _data, and _rw_n are valid
    logic        spi_ready_in;

    spi_bridge spi_bridge(
        .clk_sys_i(clk_16_i),
        .spi_sclk_i(spi_sclk_i),
        .spi_cs_ni(spi_cs_ni),
        .spi_rx_i(spi_rx_i),
        .spi_tx_io(spi_tx_io),
        .spi_addr_o(spi_addr),
        .spi_data_i(spi_rd_data),
        .spi_data_o(spi_wr_data),
        .spi_rw_no(spi_rw_n),
        .spi_valid_o(spi_valid),
        .spi_ready_i(spi_ready_in),
        .spi_ready_o(spi_ready_out)
    );

    logic clk_8;
    logic spi_en;
    logic cpu_sel;
    logic cpu_en;

    timing2 timing2(
        .clk_16_i(clk_16_i),
        .clk_8_o(clk_8),
        .clk_cpu_o(clk_cpu_o),
        .spi_valid_i(spi_valid),
        .spi_enable_o(spi_en),
        .cpu_valid_i(cpu_ready_o),
        .cpu_select_o(cpu_sel),
        .cpu_enable_o(cpu_en)
    );

    wire spi_wr_en = spi_en  && !spi_rw_n;
    wire cpu_rd_en = cpu_sel &&  bus_rw_nio;
    wire cpu_wr_en = cpu_en  && !bus_rw_nio;
    
    assign debug_o[0] = clk_8;
    assign debug_o[1] = spi_en;
    assign debug_o[2] = cpu_sel;
    assign debug_o[3] = cpu_en;
    assign debug_o[4] = clk8;
    assign debug_o[5] = spi_cs_ni;
    assign debug_o[6] = spi_rx_i;
    assign debug_o[7] = spi_tx_io;

    logic cpu_enable;
    logic cpu_read;
    logic cpu_write;
    logic io_select;
    logic pi_select;
    logic pi_read;
    logic pi_write;
    
    logic clk8;
    logic io_read;

    // Timing
    timing timing(
        .clk(clk_16_i),
        .clk8(clk8),
        .bus_rw_b(bus_rw_nio),
        .cpu_enable(cpu_enable),
        .cpu_read(cpu_read),
        .cpu_write(cpu_write),
        .io_select(io_select),
        .io_read(io_read),
        .pi_rw_b(spi_rw_n),
        .pi_select(pi_select),
        .pi_read(pi_read),
        .pi_write(pi_write),
        .pi_pending(spi_valid),
        .pi_done(spi_ready_in)
    );

    video1 video1(
        .clk_16_i(clk_16_i),
        .h_sync_o(h_sync_o),
        .v_sync_o(v_sync_o)
    );
    
    pi_ctl ctl(
        .clk_bus_i(clk_8),
        .spi_addr_i(spi_addr),
        .spi_data_i(spi_wr_data),
        .spi_wr_en_i(spi_wr_en),
        .cpu_res_no(cpu_res_nao),
        .cpu_ready_o(cpu_ready_o)
    );

    logic ram_enable;
    logic pia1_enable_before_kbd;
    logic pia2_enable;
    logic via_enable;
    logic io_enable_before_kbd;

    logic is_readonly;
    logic is_mirrored;
    
    address_decoding decode1(
        .addr(bus_addr_io),
        .ram_enable(ram_enable),
        .io_enable(io_enable_before_kbd),
        .pia1_enable(pia1_enable_before_kbd),
        .pia2_enable(pia2_enable),
        .via_enable(via_enable),
        .is_readonly(is_readonly),
        .is_mirrored(is_mirrored)
    );

    logic [7:0] kbd_data_out;
    logic kbd_enable;
    
    keyboard keyboard(
        .clk_bus_i(clk_8),
        .reset_i(cpu_res_ai),
        .spi_addr_i(spi_addr),
        .spi_data_i(spi_wr_data),
        .spi_wr_en_i(spi_wr_en),
        .bus_addr_i(bus_addr_io[1:0]),
        .bus_data_i(bus_data_io),
        .pia1_en_i(pia1_enable_before_kbd),
        .cpu_rd_en_i(cpu_rd_en),
        .cpu_wr_en_i(cpu_wr_en),
        .kbd_data_o(kbd_data_out),
        .kbd_en_o(kbd_enable)
    );

    wire pia1_enable = pia1_enable_before_kbd && !kbd_enable;
    wire io_enable = io_enable_before_kbd && !kbd_enable;
       
    // Address Decoding
    assign cpu_en_o    = cpu_enable  && cpu_ready_o;
    wire   pia1_cs     = pia1_enable && cpu_en_o;
    wire   pia2_cs     = pia2_enable && cpu_en_o;
    wire   via_cs      = via_enable  && cpu_en_o;
    wire   io_oe       = io_enable   && cpu_en_o;

    assign pia1_cs2_no = !pia1_cs;
    assign pia2_cs2_no = !pia2_cs;
    assign via_cs2_no  = !via_cs;
    assign io_oe_no    = !io_oe;

    wire ram_ce = ram_enable || !cpu_enable;
    wire ram_oe =  pi_read   || (cpu_read  && cpu_en_o);
    wire ram_we = pi_write   || (cpu_write && cpu_en_o && !is_readonly);

    assign ram_ce_no = !ram_ce;
    assign ram_oe_no = !ram_oe;
    assign ram_we_no = !ram_we;

    always @(negedge pi_read)
        if (spi_addr == 16'he80e) spi_rd_data <= { 7'h0, gfx_i };
        else spi_rd_data <= bus_data_io;
    
    assign bus_rw_nio = cpu_enable
        ? 1'bZ                  // CPU is reading/writing and therefore driving rw_b
        : !pi_write;            // RPi is reading/writing and therefore driving rw_b
    
    // 40 column PETs have 1KB of video ram, mirrored 4 times.
    // 80 column PETs have 2KB of video ram, mirrored 2 times.
    assign ram_addr_o[11:10] =
        spi_en
            ? spi_addr[11:10]            // Give RPi access to full RAM
            : is_mirrored
                ? 2'b00                  // Mirror VRAM when CPU is reading/writing to $8000-$8FFF
                : bus_addr_io[11:10];
    
    assign bus_addr_io = spi_en
        ? spi_addr                      // RPi is reading/writing, and therefore driving addr
        : { 1'b0, 16'bZ };              // CPU is reading/writing, and therefore driving addr

    assign bus_data_io =
        spi_wr_en
            ? spi_wr_data               // RPi is writing, and therefore driving data
            : kbd_enable                // 0 = Normal bus access, 1 = Intercept read of keyboard matrix
                ? kbd_data_out          // Return USB keyboard state for PIA 1 Port B ($E812)
                : 8'bZ;                 // CPU is writing and therefore driving data, or CPU/RPi are reading and RAM is driving data
endmodule
