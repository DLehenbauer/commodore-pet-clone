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
    wire video;
    
    wire h_sync;
    wire h_active;
    
    wire v_sync;
    wire v_active;
    
    reg reset = 0;
    reg pixel_clk = 0;

    initial begin
        pixel_clk = 0;
        forever begin
            #62.5 pixel_clk = ~pixel_clk;
        end
    end

    video_gen vg(
        .reset(reset),
        .pixel_clk(pixel_clk),

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
