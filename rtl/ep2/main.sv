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
    input  logic         bus_rw_ni,     // CPU 34 : 0 = writing, 1 = reading
    output logic         bus_rw_no,     // 
    output logic         bus_rw_noe,    //

    input  logic [15:0]  bus_addr_i,    // CPU 9-20, 22-25 : System address bus
    output logic [16:0]  bus_addr_o,    //
    output logic         bus_addr_oe,   //

    input  logic  [7:0]  bus_data_i,    // CPU 33-26 : System data bus
    output logic  [7:0]  bus_data_o,    //
    output logic         bus_data_oe,   //
    
    output logic [11:10] ram_addr_o,    // RAM: Intercept A11/A10 to mirror VRAM.  Must remove zero ohm
                                        //      resistors at R9 and R10.

    // SPI
    input  logic spi1_sclk_i,           // RPi 23 : GPIO 11
    input  logic spi1_cs_ni,            // RPi 24 : GPIO 8 (Also serves as !spi1_tx_oe)
    input  logic spi1_rx_i,             // RPi 19 : GPIO 10
    output logic spi1_tx_o,             // RPi 21 : GPIO 9 (Should be High-Z when CS is deasserted)

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
    output logic video_o
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
        .clk_sys_i(clk_8n),
        .spi_sclk_i(spi1_sclk_i),
        .spi_cs_ni(spi1_cs_ni),
        .spi_rx_i(spi1_rx_i),
        .spi_tx_o(spi1_tx_o),
        .spi_addr_o(spi_addr),
        .spi_data_i(spi_rd_data),
        .spi_data_o(spi_wr_data),
        .spi_rw_no(spi_rw_n),
        .spi_valid_o(spi_valid),
        .spi_ready_i(spi_ready_in),
        .spi_ready_o(spi_ready_out)
    );

    logic clk_8;
    logic clk_8n;
    logic spi_en;
    logic cpu_sel;

    timing2 timing2(
        .clk_16_i(clk_16_i),
        .clk_8_o(clk_8),
        .clk_8n_o(clk_8n),
        .clk_cpu_o(clk_cpu_o),
        .spi_valid_i(spi_valid),
        .spi_enable_o(spi_en),
        .spi_ready_o(spi_ready_in),
        .cpu_valid_i(cpu_ready_o),
        .cpu_select_o(cpu_sel),
        .cpu_enable_o(cpu_en_o)
    );

    wire spi_rd_en = spi_en &&  spi_rw_n;
    wire spi_wr_en = spi_en && !spi_rw_n;
    wire cpu_rd_en = cpu_en_o &&  bus_rw_ni;
    wire cpu_wr_en = cpu_en_o && !bus_rw_ni;
    
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
    
    address_decoding address_decoding(
        .bus_addr_i(bus_addr_i),
        .ram_en_o(ram_enable),
        .io_en_o(io_enable_before_kbd),
        .pia1_en_o(pia1_enable_before_kbd),
        .pia2_en_o(pia2_enable),
        .via_en_o(via_enable),
        .is_readonly_o(is_readonly),
        .is_mirrored_o(is_mirrored)
    );

    logic [7:0] kbd_data_out;
    logic kbd_enable;
    
    keyboard keyboard(
        .clk_bus_i(clk_8),
        .reset_i(cpu_res_ai),
        .spi_addr_i(spi_addr),
        .spi_data_i(spi_wr_data),
        .spi_wr_en_i(spi_wr_en),
        .bus_addr_i(bus_addr_i[1:0]),
        .bus_data_i(bus_data_i),
        .pia1_en_i(pia1_enable_before_kbd),
        .cpu_rd_en_i(cpu_rd_en),
        .cpu_wr_en_i(cpu_wr_en),
        .kbd_data_o(kbd_data_out),
        .kbd_en_o(kbd_enable)
    );

    wire pia1_enable = pia1_enable_before_kbd && !kbd_enable;
    wire io_enable   = io_enable_before_kbd && !kbd_enable;
       
    // Address Decoding
    wire   pia1_cs     = pia1_enable && cpu_en_o;
    wire   pia2_cs     = pia2_enable && cpu_en_o;
    wire   via_cs      = via_enable  && cpu_en_o;
    wire   io_oe       = io_enable   && cpu_en_o;

    assign pia1_cs2_no = !pia1_cs;
    assign pia2_cs2_no = !pia2_cs;
    assign via_cs2_no  = !via_cs;
    assign io_oe_no    = !io_oe;

    wire ram_ce = 1'b1;
    wire ram_oe = (ram_enable || !cpu_sel) && (spi_rd_en || cpu_rd_en);
    wire ram_we =  spi_wr_en || (cpu_wr_en && clk_cpu_o && !is_readonly);

    assign ram_ce_no = !ram_ce;
    assign ram_oe_no = !ram_oe;
    assign ram_we_no = !ram_we;

    always @(negedge clk_8) begin
        if (spi_rd_en) begin
            if (spi_addr == 17'h0e80f) spi_rd_data <= { 7'h0, gfx_i };
            else spi_rd_data <= bus_data_i;
        end
    end
    
    // FPGA drives 'bus_addr[15:0]' and 'bus_rw_n' whenever the CPU is not.
    assign bus_addr_oe = !cpu_en_o;   
    assign bus_rw_noe  = bus_addr_oe;   // Always same as 'bus_addr_oe'
    
    assign bus_rw_no   = !spi_wr_en;    // When FPGA is driving, only write when spi_wr_en is asserted.
    
    assign bus_addr_o[15:0] = spi_addr[15:0];
    
    // Note that FPGA always drives 'bus_addr[16]' (the 17th address bit).
    assign bus_addr_o[16] = bus_addr_oe
        ? spi_addr[16]      // SPI has access to the upper 64kb
        : 1'b0;             // Always set A[16]=0 for CPU and Video

    // 40 column PETs have 1KB of video ram, mirrored 4 times.
    // 80 column PETs have 2KB of video ram, mirrored 2 times.
    assign ram_addr_o[11:10] =
        spi_en
            ? spi_addr[11:10]           // Give RPi access to full RAM
            : is_mirrored               // Mirror VRAM when CPU is reading/writing to $8000-$8FFF
                ? 2'b00
                : bus_addr_i[11:10];

    // FPGA drives 'bus_data' when writing or intercepting keyboard
    assign bus_data_oe = spi_wr_en || kbd_enable;
    
    assign bus_data_o = kbd_enable
        ? kbd_data_out  // Return USB keyboard state for PIA 1 Port B ($E812)
        : spi_wr_data;
endmodule
