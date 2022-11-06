`timescale 1ns / 1ps

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

module tb();
    logic clk16;

    initial begin
        clk16 = 0;
        forever begin
            #31.25 clk16 = ~clk16;
        end
    end

    logic pi_select;
    logic pi_strobe;
    logic video_select;
    logic video_ram_strobe;
    logic video_rom_strobe;
    logic cpu_select;
    logic io_select;
    logic cpu_strobe;

    bus bus(
        .clk16(clk16),
        .clk16(clk8),
        .pi_select(pi_select),
        .pi_strobe(pi_strobe),
        .video_select(video_select),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),
        .cpu_select(cpu_select),
        .io_select(io_select),
        .cpu_strobe(cpu_strobe)
    );

    video video(
        .reset_i(reset),
        .clk16_i(clk16),
        .clk8_i(clk8),
        .cclk_i(cclk),
        .video_ram_clk_i(video_ram_clk),
        .video_rom_clk_i(video_rom_clk),
        .bus_addr_i(bus_addr_i),
        .bus_addr_o(bus_addr_o),
        .pi_addr_i(pi_addr),
        .pi_read_clk_i(pi_read_clk),
        .data_i(data_i),
        .data_o(data_o),
        .data_enable_o(data_enable),
        .cpu_write_clk_i(cpu_write_clk),
        .crtc_select_i(crtc_select),
        .h_sync_o(h_sync),
        .v_sync_o(v_sync),
        .video_o(video)
    );

endmodule
