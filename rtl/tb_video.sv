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
    wire pi_clk;
    wire video_select;
    wire video_ram_clk;
    wire video_rom_clk;
    wire cpu_select;
    wire io_select;
    wire cpu_clk;

    bus bus(
        .clk16(clk16),
        .pi_select(pi_select),
        .pi_strobe(pi_clk),
        .video_select(video_select),
        .video_ram_strobe(video_ram_clk),
        .video_rom_strobe(video_rom_clk),
        .cpu_select(cpu_select),
        .io_select(io_select),
        .cpu_strobe(cpu_clk)
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

    wire char_clk;
    
    reg reset = 0;

    wire [11:0] bus_addr;
    reg [7:0] bus_data = 8'h00;
    
    reg [7:0] h_char_displayed = 8'd3;
    reg [7:0] h_front_porch    = 8'd1;
    reg [3:0] h_sync_width     = 4'd1;
    reg [7:0] h_back_porch     = 8'd1;

    wire [7:0] h_sync_start   = h_char_displayed + h_front_porch;
    wire [7:0] h_char_total = h_sync_start + h_sync_width + h_back_porch - 1'b1;

    reg [4:0] v_char_height    = 7'd7;
    reg [6:0] v_char_displayed = 7'd2;
    reg [6:0] v_front_porch    = 7'd1;
    reg [3:0] v_sync_width     = 4'd1;
    reg [6:0] v_back_porch     = 7'd1;
    reg [4:0] v_adjust         = 5'd0;

    wire [6:0] v_sync_start   = v_char_displayed + v_front_porch;
    wire [6:0] v_char_total = v_sync_start + v_sync_width + v_back_porch - 1'b1;

    video_gen vg(
        .reset_i(reset),
        .pixel_clk_i(pixel_clk),

        .bus_addr_o(bus_addr),
        .bus_data_i(bus_data),
        .video_ram_clk_i(video_ram_clk),
        .video_rom_clk_i(video_rom_clk),

        .h_char_total_i(h_char_total),
        .h_char_displayed_i(h_char_displayed),
        .h_sync_start_i(h_sync_start),
        .h_sync_width_i(h_sync_width),

        .v_char_height_i(v_char_height),
        .v_char_total_i(v_char_total),
        .v_char_displayed_i(v_char_displayed),
        .v_sync_start_i(v_sync_start),
        .v_sync_width_i(v_sync_width),
        .v_adjust_i(v_adjust),

        .display_start_i(14'h0000),

        .h_sync_o(h_sync),
        .h_active_o(h_active),
        
        .v_sync_o(v_sync),
        .v_active_o(v_active)
    );

    wire active = h_active & v_active;
    reg [11:0] last_ram_addr_read;
    reg [11:0] last_rom_addr_read;

    always @(negedge video_ram_clk)
        last_ram_addr_read <= bus_addr;

    always @(negedge video_rom_clk)
        last_rom_addr_read <= bus_addr;

    task skip_to_next_frame;
        @(posedge v_sync);
        @(posedge active);
    endtask

    reg [3:0] x;
    reg [3:0] y;

    task test_character_pixels;
        h_char_displayed = 8'd1;
        h_front_porch    = 8'd0;
        h_sync_width     = 4'd1;
        h_back_porch     = 8'd0;

        v_char_displayed = 7'd1;
        v_front_porch    = 7'd0;
        v_sync_width     = 4'd1;
        v_back_porch     = 7'd0;
        v_adjust         = 5'd0;

        v_char_height    = 7'd7;        // Height of characters in pixels (-1)

        bus_data = 8'h00;

        skip_to_next_frame();
        $display("[%t] Test Pixel Generation", $time);

        for (x = 0; x < 8; x++) begin
            for (y = 0; y < 8; y++) begin
                
            end
        end
    endtask

    initial begin
        #1 reset = 1'b1;
        #1 reset = 1'b0;

        $dumpfile("out.vcd");
        $dumpvars;

        //test_character_pixels();

        skip_to_next_frame();
        skip_to_next_frame();

        #10 $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
