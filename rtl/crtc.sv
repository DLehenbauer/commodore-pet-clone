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

module crtc(
    input reset,

    input            crtc_select,
    input     [16:0] bus_addr,
    input      [7:0] bus_data_in,
    input            cpu_write,

    input [15:0]     pi_addr,               // A0..4 select CRTC registers R0..17
    input            pi_read,

    output reg [7:0] crtc_data_out,
    output           crtc_data_out_enable,

    output reg [4:0] crtc_address_register,   // Internally selects R0..17.  Exposed for testing.
    output     [7:0] crtc_r,                  // Contents of currently selected R0..17.  Exposed for testing.

    output [7:0] h_total,
    output [7:0] h_displayed,
    output [7:0] h_sync_pos,
    output [7:4] v_sync_width,
    output [3:0] h_sync_width,
    output [6:0] v_total,
    output [4:0] v_line_adjust,
    output [6:0] v_displayed,
    output [6:0] v_sync_pos,
    output [4:0] char_height
);
    localparam R0_H_TOTAL           = 0,    // [7:0] Total displayed and non-displayed characters, minus one, per horizontal line.
                                            //       The frequency of HSYNC is thus determined by this register.
                
               R1_H_DISPLAYED       = 1,    // [7:0] Number of displayed characters per horizontal line.
                
               R2_H_SYNC_POS        = 2,    // [7:0] Position of the HSYNC on the horizontal line, in terms of the character location number on the line.
                                            //       The position of the HSYNC determines the left-to-right location of the displayed text on the video screen.
                                            //       In this way, the side margins are adjusted.

               R3_SYNC_WIDTH        = 3,    // [7:4] Width of VSYNC in scan lines
                                            // [3:0] Width of HSYNC in character clock times

               R4_V_TOTAL           = 4,    // [6:0] Total number of character rows in a frame, minus one. This register, along with R5,
                                            //       determines the overall frame rate, which should be close to the line frequency to
                                            //       ensure flicker-free appearance. If the frame time is adjusted to be longer than the
                                            //       period of the line frequency, then /RES may be used to provide absolute synchronism.

               R5_V_LINE_ADJUST     = 5,    // [4:0] Number of additional scan lines needed to complete an entire frame scan and is intended
                                            //       as a fine adjustment for the video frame time.

               R6_V_DISPLAYED       = 6,    // [6:0] Number of displayed character rows in each frame. In this way, the vertical size of the
                                            //       displayed text is determined.
            
               R7_V_SYNC_POS        = 7,    // [6:0] Selects the character row time at which the VSYNC pulse is desired to occur and, thus,
                                            //       is used to position the displayed text in the vertical direction.
            
               R9_SCAN_LINE         = 9;    // [4:0] Number of scan lines per character row, including spacing.
 
    reg [7:0] r [17:0];

    assign crtc_r = r[crtc_address_register];

    assign h_total = r[R0_H_TOTAL];
    assign h_displayed = r[R1_H_DISPLAYED];
    assign h_sync_pos = r[R2_H_SYNC_POS];
    assign v_sync_width = r[R3_SYNC_WIDTH][7:4];
    assign h_sync_width = r[R3_SYNC_WIDTH][3:0];
    assign v_total = r[R4_V_TOTAL];
    assign v_line_adjust = r[R5_V_LINE_ADJUST];
    assign v_displayed = r[R6_V_DISPLAYED];
    assign v_sync_pos = r[R7_V_SYNC_POS];
    assign char_height = r[R9_SCAN_LINE];
    
    always @(negedge cpu_write or posedge reset) begin
        if (reset) begin
            // On reset, we initialize the CRTC register to produce the 15.625 KHz / 60 Hz timing
            // of a non-CRTC PET.  These values are then overwritten during boot if a CRTC Edit
            // ROM is used.
            r[R0_H_TOTAL]           = 8'd63;
            r[R1_H_DISPLAYED]       = 8'd40;
            r[R2_H_SYNC_POS]        = 8'd48;
            r[R3_SYNC_WIDTH]        = 8'h15;
            r[R4_V_TOTAL]           = 7'd32;
            r[R5_V_LINE_ADJUST]     = 5'd00;
            r[R6_V_DISPLAYED]       = 7'd25;
            r[R7_V_SYNC_POS]        = 7'd28;
            r[8] = 8'h00;
            r[R9_SCAN_LINE]         = 5'd07;
            r[10] = 8'h00;
            r[11] = 8'h00;
            r[12] = 8'h10;
            r[13] = 8'h00;
            r[14] = 8'h00;
            r[15] = 8'h00;
            r[16] = 8'h00;
        end else begin
            if (crtc_select) begin
                // 'crtc_select' is high when the bus address is in the $E8xx range.  Even addresses
                // map to CRTC register 0 and odd addresses are CRTC register 1.
                if (bus_addr[0]) r[crtc_address_register] <= bus_data_in;
                else crtc_address_register <= bus_data_in[4:0];
            end
        end
    end

    wire pi_crtc_select = 16'he8f0 <= pi_addr && pi_addr <= 16'he8ff;
    wire [4:0] pi_crtc_reg = { 1'b0, pi_addr[3:0] };

    // Update 'crtc_data_out' on the rising edge of pi_read so it is available when 'pi_data_reg'
    // is updated on the falling edge.
    always @(posedge pi_read) begin
        if (pi_crtc_select) begin
            crtc_data_out <= r[pi_crtc_reg];
        end
    end

    assign crtc_data_out_enable = pi_crtc_select;
endmodule