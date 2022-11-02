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
    reg sys_clk = 0;

    initial begin
        sys_clk = 0;
        forever begin
            #31.25 sys_clk = ~sys_clk;
        end
    end

    logic [3:0] clk_div = 0;

    always @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            clk_div <= '0;
        end else begin
            clk_div <= clk_div + 1'b1;
        end
    end

    logic cclk;
    assign cclk = clk_div[3];

    reg reset = 0;

    logic [7:0] h_char_displayed = 8'd3;
    logic [7:0] h_front_porch    = 8'd1;
    logic [3:0] h_sync_width     = 4'd1;
    logic [7:0] h_back_porch     = 8'd1;

    logic [7:0] h_sync_pos;
    assign h_sync_pos = h_char_displayed + h_front_porch;
    
    logic [7:0] h_char_total;
    assign h_char_total = h_sync_pos + h_sync_width + h_back_porch;

    logic [4:0] h_char_pixel_size  = 7'd8;

    logic [7:0] v_char_displayed = 8'd2;
    logic [7:0] v_front_porch    = 8'd1;
    logic [3:0] v_sync_width     = 4'd1;
    logic [7:0] v_back_porch     = 8'd1;

    logic [7:0] v_sync_pos;
    assign v_sync_pos = v_char_displayed + v_front_porch;
    
    logic [7:0] v_char_total;
    assign v_char_total = v_sync_pos + v_sync_width + v_back_porch;

    logic [4:0] v_char_pixel_size  = 7'd8;
    logic [4:0] v_adjust           = 5'd0;

    crtc_sync_gen sync_gen(
        .cclk_i(cclk),
        .reset_i(reset),

        .screen_addr_i(14'h0000),

        .h_char_total_i(h_char_total - 1'b1),
        .h_char_displayed_i(h_char_displayed),
        .h_sync_start_i(h_sync_pos),
        .h_sync_width_i(h_sync_width),

        .v_char_pixel_size_i(v_char_pixel_size - 1'b1),
        .v_char_total_i(v_char_total - 1'b1),
        .v_char_displayed_i(v_char_displayed),
        .v_sync_start_i(v_sync_pos),
        .v_sync_width_i(v_sync_width),
        .v_adjust_i(v_adjust),

        .display_enable_o(display_enable),
        .h_sync_o(h_sync),
        .v_sync_o(v_sync)
    );

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        @(posedge sys_clk) reset = 1'b0;
        @(posedge sys_clk) reset = 1'b1;
        @(posedge sys_clk) reset = 1'b0;

        #1000000 $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
