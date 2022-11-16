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