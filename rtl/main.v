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

module timing(
    input clk,

    output phi2,
    input res_b,

    input  bus_rw_b,
    output cpu_enable,
    output cpu_read_strobe,
    output cpu_write_strobe,
    output io_select,
    input  pi_rw_b,
    output pi_select,
    output pi_read_strobe,
    output pi_write_strobe,
    input  pi_pending,
    output pi_done
);
    wire pi_enable;

    bus bus(
        .clk16(clk),
        .pi_select(pi_select),
        .pi_strobe(pi_enable),
        .cpu_select(cpu_enable),
        .io_select(io_select),
        .cpu_strobe(phi2)
    );

    assign cpu_read_strobe  =  bus_rw_b && phi2;
    assign cpu_write_strobe = !bus_rw_b && phi2;

    wire pi_strobe;

    sync pi_sync(
        .clk(pi_enable),
        .pending(pi_pending),
        .done(pi_done),
        .strobe(pi_strobe)
    );

    assign pi_read_strobe   =  pi_rw_b && pi_strobe;
    assign pi_write_strobe  = !pi_rw_b && pi_strobe;
endmodule

module pi_ctl(
    input pi_write_strobe,
    input [15:0] pi_addr,
    input [7:0] pi_data,
    output res_b,
    output rdy
);
    parameter RES_B = 0,
              RDY   = 1;

    reg [1:0] state = 2'b00;

    always @(negedge pi_write_strobe) begin
        if (pi_addr === 16'hE80F) state <= pi_data[1:0];
    end
    
    assign res_b = state[RES_B];
    assign rdy   = state[RDY];
endmodule

module main (
    // System Bus
    input pi_rw_b,              // RPi 0       : 0 = CPU writing, 1 = CPU reading
    input [15:0] pi_addr,       // RPi 5-19, 1 : Address of requested read/write
    inout [7:0]  pi_data,       // RPi 20-27   : Data bits transfered to/from RPi

    inout bus_rw_b,             // CPU 34          : 0 = CPU writing, 1 = CPU reading
    inout [16:0] bus_addr,      // CPU 9-20, 22-25 : System address bus
    inout [7:0] bus_data,       // CPU 33-26       : System data bus
    
    output [11:10] ram_addr,    // RAM: Intercept A11/A10 to mirror VRAM.  Must remove zero ohm
                                //      resistors at R9 and R10.

    // Timing
    input pi_clk,               // RPi  4 : Clock generated by RPi
    output phi2,                // CPU 37 : 1 MHz cpu clock
    output read_strobe_b,       // RAM 24 : 0 = enabled (oe_b),  1 = High impedance
    output write_strobe_b,      // RAM 29 : 0 = active (we_b),   1 = Not active
    output vsync,

    // CPU
    input  pi_pending_b,        // RPi  2 : (See 'wire' assignment below)
    output pi_done_b,           // RPi  3 : (See 'wire' assignment below)

    inout  cpu_res_b,           // CPU 40 : 0 = reset, 1 = normal operation
    output cpu_rdy,             // CPU  2 : 0 = halt, 1 = run
    inout  cpu_irq_b,           // CPU  4 : 0 = interrupt requested, 1 = normal operation
    inout  cpu_nmi_b,           // CPU  6 : 0 = interrupt reuested, 1 = normal operation
    input  cpu_sync,

    // Address Decoding
    output cpu_be,              // CPU 36 : 1 = High impedance,  0 = enabled (be)
    output ram_ce_b,            // RAM 22 : 0 = enabled (ce_b),  1 = High impedance
    output pia1_cs2_b,
    output pia2_cs2_b,
    output via_cs2_b,
    output io_oe_b,

    input diag,
    input cb2,
    output audio,

    input gfx,
    output hsync,
    output video,
    
    // Reserved by DevBoard
    // (See http://land-boards.com/blwiki/index.php?title=Cyclone_II_EP2C5_Mini_Dev_Board#I.2FO_Pin_Mapping)
    output P3_LED_D2,           // Low to Light LED
    output P7_LED_D4,           // Low to Light LED
    output P9_LED_D5,           // Low to Light LED
    input  P17_50MHz,           // Clock input
    input  P26_1V2,             // Connected to Vcc 1.2V.  Only needed for EP2C8.  "Zero ohm" resistor can be removed and the pin used as normal.
    input  P27_GND,             // Connected to GND.  Only needed for EP2C8.  "Zero ohm" resistor can be removed and the pin used as normal.
    input  P73_POR              // 10uF capacitor to ground + 10K resistor to Vcc (Presumably for power up reset?)    
    // inout P144_KEY           // Pushbutton used for 'cpu_res_b'.
);
    wire pi_pending = !pi_pending_b;
    wire pi_done;
    assign pi_done_b = !pi_done;
        
    wire cpu_enable;
    wire cpu_read_strobe;
    wire cpu_write_strobe;
    wire io_select;
    wire pi_select;
    wire pi_read_strobe;
    wire pi_write_strobe;

    wire res_b;
    wire irq_b = 1'b1;
    wire nmi_b = 1'b1;

    // res_b, irq_b, and nmi_b are open drain for wire-OR (see also *.qsf)
    assign cpu_res_b = res_b ? 1'bZ : 1'b0;
    assign cpu_irq_b = irq_b ? 1'bZ : 1'b0;
    assign cpu_nmi_b = nmi_b ? 1'bZ : 1'b0;

    assign P3_LED_D2 = pi_pending_b;
    assign P7_LED_D4 = pi_done_b;
    assign P9_LED_D5 = !res_b;
    
    wire clk16;     // 16 MHz clock from PLL
    wire clk25;     // 25 MHz clock from PLL
    
    pll pll(
        .inclk0(P17_50MHz),
        .c0(clk16),
        .c1(clk25)
    );
    
    // Timing
    timing timing(
        .clk(clk16),
        .res_b(cpu_res_b),
        .phi2(phi2),
        .bus_rw_b(bus_rw_b),
        .cpu_enable(cpu_enable),
        .cpu_read_strobe(cpu_read_strobe),
        .cpu_write_strobe(cpu_write_strobe),
        .io_select(io_select),
        .pi_rw_b(pi_rw_b),
        .pi_select(pi_select),
        .pi_read_strobe(pi_read_strobe),
        .pi_write_strobe(pi_write_strobe),
        .pi_pending(pi_pending),
        .pi_done(pi_done)
    );
    
    pi_ctl ctl(
        .pi_write_strobe(pi_write_strobe),
        .pi_addr(pi_addr),
        .pi_data(pi_data),
        .res_b(res_b),
        .rdy(cpu_rdy)
    );
    
    wire ram_enable;
    wire pia1_enable;
    wire pia2_enable;
    wire via_enable;
    wire crtc_enable;
    wire io_enable;

    wire is_readonly;
    wire is_mirrored;
    
    address_decoding decode1(
        .clk(io_select),
        .addr(bus_addr),
        .ram_enable(ram_enable),
        .io_enable(io_enable),
        .pia1_enable(pia1_enable),
        .pia2_enable(pia2_enable),
        .via_enable(via_enable),
        .crtc_enable(crtc_enable),
        .is_readonly(is_readonly),
        .is_mirrored(is_mirrored)
    );

    wire [7:0] pia_data_out;
    wire pia1_oe;
    
    pia1 pia1(
        .addr(bus_addr),
        .data_in(bus_data),
        .data_out(pia_data_out),
        .res_b(cpu_res_b),
        .pi_write_strobe(pi_write_strobe),
        .cpu_select(io_select),
        .cpu_write_strobe(cpu_write_strobe),
        .oe(pia1_oe)
    );
    
    hvSync hvSync(
        .clk16(clk16),
        .hsync(hsync),
        .vsync(vsync)
    );
    
    // Address Decoding
    assign cpu_be   = cpu_enable && cpu_rdy;
    wire   pia1_cs  = pia1_enable && cpu_be;
    wire   pia2_cs  = pia2_enable && cpu_be;
    wire   via_cs   = via_enable && cpu_be;
    wire   io_oe    = (pia1_cs && pia1_oe) || pia2_cs || via_cs;

    assign pia1_cs2_b = !pia1_cs;
    assign pia2_cs2_b = !pia2_cs;
    assign via_cs2_b  = !via_cs;
    assign io_oe_b    = !io_oe;

    assign ram_ce_b       = !(ram_enable || !cpu_enable);
    wire read_strobe      =  pi_read_strobe || (cpu_read_strobe && cpu_be);
    wire write_strobe     = pi_write_strobe || (cpu_write_strobe && cpu_be && !is_readonly);

    assign read_strobe_b  = !read_strobe;
    assign write_strobe_b = !write_strobe;

    reg [7:0] pi_data_reg = 8'hee;

    always @(negedge pi_read_strobe)
        if (pi_addr == 16'he80e) pi_data_reg <= { 7'h0, gfx };
        else pi_data_reg <= bus_data;
    
    assign bus_rw_b = cpu_enable
        ? 1'bZ                  // CPU is reading/writing and therefore driving rw_b
        : !pi_write_strobe;     // RPi is reading/writing and therefore driving rw_b
    
    // 40 column PETs have 1KB of video ram, mirrored 4 times.
    // 80 column PETs have 2KB of video ram, mirrored 2 times.
    assign ram_addr[11:10] = pi_select
        ? pi_addr[11:10]            // Give RPi access to full RAM
        : is_mirrored
            ? 2'b00                 // Mirror VRAM when CPU is reading/writing to $8000-$8FFF
            : bus_addr[11:10];
    
    assign bus_addr = pi_select
        ? {1'b0, pi_addr}       // RPi is reading/writing, and therefore driving addr
        : {1'b0, 16'bZ};        // CPU is reading/writing, and therefore driving addr

    assign pi_data = pi_rw_b
        ? pi_data_reg           // RPi is reading from register
        : 8'bZ;                 // RPi is writing to bus

    assign bus_data =
        pi_write_strobe
            ? pi_data           // RPi is writing, and therefore driving data
            : !pia1_oe          // 0 = data from pia1 is disabled, 1 = normal bus access (including pia1)
                ? pia_data_out  // When PIA1 is not enabled (oe = 0) the FPGA is servicing a read on behalf of the PIA.
                : 8'bZ;         // Is writing and therefore driving data, or CPU/RPi are reading and RAM is driving data

    // Audio
    assign audio = cb2 && diag;

    // Video
    assign video = 1'b0;
endmodule