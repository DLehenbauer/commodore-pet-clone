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
    logic clk16 = 0;

    initial begin
        forever begin
            #31.25 clk16 = ~clk16;
        end
    end

    logic clk8 = 0;

    always @(posedge clk16) begin
        clk8 = ~clk8;
    end

    logic pixel_clk;
    assign pixel_clk = clk8;
    
    logic reset;
    logic [7:0] pixels;
    logic display_enabled;
    logic reverse_video;
    logic video;

    dotgen dotgen(
        .reset_i(reset),
        .pixel_clk_i(pixel_clk),
        .pixels_i(pixels),
        .display_enabled_i(display_enabled),
        .reverse_video_i(reverse_video),
        .video_o(video)
    );

    initial begin
        display_enabled = 1'b1;
        pixels = 8'h80;
        reverse_video = '0;

        #1 reset = 1'b1;
        #1 reset = 1'b0;

        $dumpfile("out.vcd");
        $dumpvars;

        #10000;

        #10 $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
