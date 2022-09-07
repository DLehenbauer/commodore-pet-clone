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
    reg clk16 = 0;

    initial begin
        clk16 = 0;
        forever begin
            #31.25 clk16 = ~clk16;
        end
    end

    wire pi_select;
    wire pi_strobe;
    wire video_select;
    wire video_ram_strobe;
    wire video_rom_strobe;
    wire cpu_select;
    wire io_select;
    wire cpu_strobe;

    bus bus(
        .clk16(clk16),
        .pi_select(pi_select),
        .pi_strobe(pi_strobe),
        .video_select(video_select),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),
        .cpu_select(cpu_select),
        .io_select(io_select),
        .cpu_strobe(cpu_strobe)
    );

    reg pixel_clk = 0;

    always @(posedge clk16) begin
        pixel_clk = ~pixel_clk;
    end

    wire video;
    
    wire h_sync;
    wire h_active;
    
    wire v_sync;
    wire v_active;
    
    reg reset = 0;

    wire [11:0] video_addr;
    reg [7:0] data_in = 8'h01;
    
    video_gen vg(
        .reset(reset),
        .pixel_clk(pixel_clk),

        .addr_out(video_addr),
        .data_in(8'h01),
        .video_ram_strobe(video_ram_strobe),
        .video_rom_strobe(video_rom_strobe),

        .h_char_total(8'd7),
        .h_char_displayed(8'd3),
        .h_sync_pos(8'd4),
        .h_sync_width(4'd2),

        .v_char_height(5'd7),
        .v_char_total(7'd6),
        .v_char_displayed(7'd2),
        .v_sync_pos(7'd3),
        .v_sync_width(4'd1),
        .v_adjust(5'd4),

        .h_sync(h_sync),
        .h_active(h_active),
        
        .v_sync(v_sync),
        .v_active(v_active)
    );

    wire [16:0] full_video_addr = { 5'b01000, video_addr };

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 reset = 1'b1;
        #1 reset = 1'b0;

        #1000000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
