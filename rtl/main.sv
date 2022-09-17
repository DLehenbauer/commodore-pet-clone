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
    output clk8,
    output phi2,
    input  bus_rw_b,
    output cpu_enable,
    output cpu_read,
    output cpu_write,
    output io_select,
    output io_read,
    output video_select,
    output video_ram_strobe,
    output video_rom_strobe,
    input  pi_rw_b,
    output pi_select,
    output pi_read,
    output pi_write,
    input  pi_pending,
    output pi_done
);
    wire pi_enable;

    bus bus(
        .clk16(clk),
        .clk8(clk8),
        .pi_select(pi_select),
        .pi_strobe(pi_enable),
        .video_select(video_select),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),
        .cpu_select(cpu_enable),
        .io_select(io_select),
        .cpu_strobe(phi2)
    );

    assign cpu_read  =  bus_rw_b && phi2;
    assign cpu_write = !bus_rw_b && phi2;

    // io_read signals that the FPGA should drive 'bus_data' when intercepting reads
    // from the CPU (e.g., for keyboard).  It transitions to high after the CPU is enabled
    // and the bus_addr/bus_rw_b are valid, but before the positive edge of the CPU clock
    // (i.e., phi2).
    assign io_read = bus_rw_b && io_select;

    wire pi_strobe;

    sync pi_sync(
        .select(pi_select),
        .enable(pi_enable),
        .pending(pi_pending),
        .done(pi_done),
        .strobe(pi_strobe)
    );

    assign pi_read  =  pi_rw_b && pi_strobe;
    assign pi_write = !pi_rw_b && pi_strobe;
endmodule

module pi_ctl(
    input pi_write,
    input [15:0] pi_addr,
    input [7:0] pi_data,
    output res_b,
    output rdy
);
    localparam RES_B = 0,
               RDY   = 1;

    reg [1:0] state = 2'b00;

    always @(negedge pi_write) begin
        if (pi_addr === 16'hE80F) state <= pi_data[1:0];
    end
    
    assign res_b = state[RES_B];
    assign rdy   = state[RDY];
endmodule

module main (
    // System Bus
    inout bus_rw_b,             // CPU 34          : 0 = CPU writing, 1 = CPU reading
    inout [16:0] bus_addr,      // CPU 9-20, 22-25 : System address bus
    inout [7:0] bus_data,       // CPU 33-26       : System data bus
    
    output [11:10] ram_addr,    // RAM: Intercept A11/A10 to mirror VRAM.  Must remove zero ohm
                                //      resistors at R9 and R10.

    // Pi
    input pi_rw_b,              // RPi 0       : 0 = CPU writing, 1 = CPU reading
    input [15:0] pi_addr,       // RPi 5-19, 1 : Address of requested read/write
    inout [7:0]  pi_data,       // RPi 20-27   : Data bits transfered to/from RPi
    input  pi_pending,
    output pi_done,

    // Timing
    input clk16,                // 16 MHz master clock
    output phi2,                // CPU 37 : 1 MHz cpu clock
    output ram_oe_b,            // RAM 24 : 0 = output enabled, 1 = High impedance
    output ram_we_b,            // RAM 29 : 0 = write enabled,  1 = Not active

    // CPU
    input reset_in,
    output res_b_out,
    output cpu_rdy,             // CPU  2 : 0 = halt,  1 = run
    input  cpu_sync,

    // Address Decoding
    output cpu_be,              // CPU 36 : 1 = High impedance,  0 = enabled (be)
    output ram_ce_b,            // RAM 22 : 0 = enabled (ce_b),  1 = High impedance
    output pia1_cs2_b,
    output pia2_cs2_b,
    output via_cs2_b,
    output io_oe_b,

    // Video
    input gfx,
    output hsync,
    output vsync,
    output video
);
    wire cpu_enable;
    wire cpu_read;
    wire cpu_write;
    wire io_select;
    wire pi_select;
    wire pi_read;
    wire pi_write;
    
    wire clk8;
    wire io_read;
    wire video_select;
    wire video_ram_strobe;
    wire video_rom_strobe;

    wire reset = reset_in & !res_b_out;

    // Timing
    timing timing(
        .clk(clk16),
        .clk8(clk8),
        .phi2(phi2),
        .bus_rw_b(bus_rw_b),
        .cpu_enable(cpu_enable),
        .cpu_read(cpu_read),
        .cpu_write(cpu_write),
        .io_select(io_select),
        .io_read(io_read),
        .video_select(video_select),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),
        .pi_rw_b(pi_rw_b),
        .pi_select(pi_select),
        .pi_read(pi_read),
        .pi_write(pi_write),
        .pi_pending(pi_pending),
        .pi_done(pi_done)
    );
    
    pi_ctl ctl(
        .pi_write(pi_write),
        .pi_addr(pi_addr),
        .pi_data(pi_data),
        .res_b(res_b_out),
        .rdy(cpu_rdy)
    );

    wire [7:0] crtc_data_out;
    wire crtc_data_out_enable;

    crtc ctrc(
        .reset(reset),
        .crtc_select(crtc_enable),
        .bus_addr(bus_addr),
        .bus_data_in(bus_data),
        .cpu_write(cpu_write),

        .pi_addr(pi_addr),
        .pi_data_in(pi_data),
        .pi_read(pi_read),

        .crtc_data_out(crtc_data_out),
        .crtc_data_out_enable(crtc_data_out_enable)
    );
    
    wire ram_enable;
    wire pia1_enable_before_kbd;
    wire pia2_enable;
    wire via_enable;
    wire crtc_enable;
    wire io_enable_before_kbd;

    wire is_readonly;
    wire is_mirrored;
    
    address_decoding decode1(
        .addr(bus_addr),
        .ram_enable(ram_enable),
        .io_enable(io_enable_before_kbd),
        .pia1_enable(pia1_enable_before_kbd),
        .pia2_enable(pia2_enable),
        .via_enable(via_enable),
        .crtc_enable(crtc_enable),
        .is_readonly(is_readonly),
        .is_mirrored(is_mirrored)
    );

    wire [7:0] kbd_data_out;
    wire kbd_enable;
    
    keyboard keyboard(
        .pi_addr(pi_addr),
        .pi_data(pi_data),
        .pi_write(pi_write),
        .bus_addr(bus_addr),
        .bus_data_in(bus_data),
        .bus_rw_b(bus_rw_b),
        .pia1_enabled_in(pia1_enable_before_kbd),
        .io_read(io_read),
        .cpu_write(cpu_write),
        .kbd_data_out(kbd_data_out),
        .kbd_enable(kbd_enable)
    );

    wire pia1_enable = pia1_enable_before_kbd && !kbd_enable;
    wire io_enable = io_enable_before_kbd && !kbd_enable;
    
    wire [11:0] video_addr;

    video v(
        .pixel_clk(clk8),
        .reset(reset),
        .addr_out(video_addr),
        .data_in(bus_data),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),
        .video_out(video),
        .h_sync(hsync),
        .v_sync(vsync)
    );
    
    // Address Decoding
    assign cpu_be   = cpu_enable && cpu_rdy;
    wire   pia1_cs  = pia1_enable && cpu_be;
    wire   pia2_cs  = pia2_enable && cpu_be;
    wire   via_cs   = via_enable && cpu_be;
    wire   io_oe    = io_enable && cpu_be;

    assign pia1_cs2_b = !pia1_cs;
    assign pia2_cs2_b = !pia2_cs;
    assign via_cs2_b  = !via_cs;
    assign io_oe_b    = !io_oe;

    wire ram_ce = ram_enable || (!cpu_enable && !crtc_data_out_enable);
    wire ram_oe =  pi_read || video_select || (cpu_read  && cpu_be);
    wire ram_we = pi_write || (cpu_write && cpu_be && !is_readonly);

    assign ram_ce_b = !ram_ce;
    assign ram_oe_b = !ram_oe;
    assign ram_we_b = !ram_we;

    reg [7:0] pi_data_reg = 8'hxx;

    always @(negedge pi_read)
        if (pi_addr == 16'he80e) pi_data_reg <= { 7'h0, gfx };
        else if (crtc_data_out_enable) pi_data_reg <= crtc_data_out;
        else pi_data_reg <= bus_data;
    
    assign bus_rw_b = cpu_enable
        ? 1'bZ                  // CPU is reading/writing and therefore driving rw_b
        : !pi_write;            // RPi is reading/writing and therefore driving rw_b
    
    // 40 column PETs have 1KB of video ram, mirrored 4 times.
    // 80 column PETs have 2KB of video ram, mirrored 2 times.
    assign ram_addr[11:10] =
        pi_select
            ? pi_addr[11:10]            // Give RPi access to full RAM
            : video_select
                ? video_addr[11:10]
                : is_mirrored
                    ? 2'b00             // Mirror VRAM when CPU is reading/writing to $8000-$8FFF
                    : bus_addr[11:10];
    
    assign bus_addr = pi_select
        ? {1'b0, pi_addr}           // RPi is reading/writing, and therefore driving addr
        : video_select
            ? { 5'b01000, video_addr }
            : {1'b0, 16'bZ};        // CPU is reading/writing, and therefore driving addr

    assign pi_data = pi_rw_b
        ? pi_data_reg           // RPi is reading from register
        : 8'bZ;                 // RPi is writing to bus

    assign bus_data =
        pi_write
            ? pi_data           // RPi is writing, and therefore driving data
            : kbd_enable        // 0 = Normal bus access, 1 = Intercept read of keyboard matrix
                ? kbd_data_out  // Return USB keyboard state for PIA 1 Port B ($E812)
                : 8'bZ;         // CPU is writing and therefore driving data, or CPU/RPi are reading and RAM is driving data
endmodule