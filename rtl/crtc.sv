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
    input logic reset,

    input logic        crtc_select,
    input logic [16:0] bus_addr,
    input logic [7:0]  bus_data_in,
    input logic        cpu_write,

    input logic [15:0] pi_addr,               // A0..4 select CRTC registers R0..17
    input logic        pi_read,

    output logic [7:0] crtc_data_out,
    output logic       crtc_data_out_enable,

    output logic [4:0] crtc_address_register,   // Internally selects R0..17.  Exposed for testing.
    output logic [7:0] crtc_r,                  // Contents of currently selected R0..17.  Exposed for testing.

    output logic [7:0] h_total,
    output logic [7:0] h_displayed,
    output logic [7:0] h_sync_pos,
    output logic [3:0] v_sync_width,
    output logic [3:0] h_sync_width,
    output logic [6:0] v_total,
    output logic [4:0] v_line_adjust,
    output logic [6:0] v_displayed,
    output logic [6:0] v_sync_pos,
    output logic [4:0] char_height
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
 
    logic [7:0] r[17:0];

    assign crtc_r = r[crtc_address_register];

    assign h_total       = r[R0_H_TOTAL];
    assign h_displayed   = r[R1_H_DISPLAYED];
    assign h_sync_pos    = r[R2_H_SYNC_POS];
    assign v_sync_width  = r[R3_SYNC_WIDTH][7:4];
    assign h_sync_width  = r[R3_SYNC_WIDTH][3:0];
    assign v_total       = r[R4_V_TOTAL][6:0];
    assign v_line_adjust = r[R5_V_LINE_ADJUST][4:0];
    assign v_displayed   = r[R6_V_DISPLAYED][6:0];
    assign v_sync_pos    = r[R7_V_SYNC_POS][6:0];
    assign char_height   = r[R9_SCAN_LINE][4:0];
    
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

module crtc_sync_gen(
    input logic cclk_i,                         // 1 MHz character clock
    input logic reset_i,                        // System reset

    input  logic [13:0] screen_addr_i,          // Display start address

    input logic [7:0] h_char_total_i,           // Total width of scanline in character cols (-1)
    input logic [7:0] h_char_displayed_i,       // Number of character cols displayed per row
    input logic [7:0] h_sync_start_i,           // Position of horizontal sync pulse in character cols
    input logic [3:0] h_sync_width_i,           // Width of horizontal sync pulse in character cols 

    input logic [4:0] v_char_pixel_size_i,      // Height of one character in pixels (-1)
    input logic [7:0] v_char_total_i,           // Total height of frame in character rows (-1)
    input logic [7:0] v_char_displayed_i,       // Number character rows displayed per frame
    input logic [7:0] v_sync_start_i,           // Position of vertical sync pulse in character rows
    input logic [3:0] v_sync_width_i,           // Width of vertical sync pulse in character rows
    input logic [4:0] v_adjust_i,               // Fine vertical adjustment in scanlines

    output logic display_enable_o,
    output logic h_sync_o,
    output logic v_sync_o,

    output logic [13:0] ma_o,                   // Refresh address lines
    output logic [4:0] ra_o                     // Raster address lines
);
    logic [7:0] h_col_ctr_d, h_col_ctr_q;
    logic h_start, h_end;
    logic h_display_d, h_display_q;
    logic [3:0] h_sync_ctr_d, h_sync_ctr_q;
    logic h_sync_d;

    logic [4:0] v_scanline_ctr_d;
    logic [6:0] v_row_ctr_d, v_row_ctr_q;
    logic v_start, v_end;
    logic v_display_d, v_display_q;
    logic [3:0] v_sync_ctr_d, v_sync_ctr_q;
    logic v_sync_d;

    logic [13:0] row_addr_d, row_addr_q;
    logic [13:0] ma_d;

    always_comb begin
        // Horizontal character counter & start of line pulse
        h_start = h_col_ctr_q == h_char_total_i;
        if (h_start) h_col_ctr_d = '0;
        else h_col_ctr_d = h_col_ctr_q + 1'b1;

        // Horizontal display enable
        h_end = h_col_ctr_d == h_char_displayed_i;
        if (h_end) h_display_d = '0;
        else if (h_start) h_display_d = 1'b1;
        else h_display_d = h_display_q;

        // Horizontal sync
        if (h_sync_ctr_d == h_sync_width_i) h_sync_d = 1'b0;
        else if (h_col_ctr_d == h_sync_start_i) h_sync_d = 1'b1;
        else h_sync_d = h_sync_o;

        // Horizontal sync width counter
        if (h_sync_d) h_sync_ctr_d = h_sync_ctr_q + 1'b1;
        else h_sync_ctr_d = '0;

        v_scanline_ctr_d = ra_o;
        v_row_ctr_d      = v_row_ctr_q;
        v_display_d      = v_display_q;
        v_start          = v_row_ctr_q == v_char_total_i;
        v_end            = '0;
        v_sync_ctr_d     = v_sync_ctr_q;
        v_sync_d         = v_sync_o;
        row_addr_d       = row_addr_q;

        if (h_start) begin
            // Vertical scanline counter
            if (ra_o == v_char_pixel_size_i) begin
                v_scanline_ctr_d = '0;

                // Vertical row counter
                if (v_start) begin
                    v_row_ctr_d = '0;
                    row_addr_d  = screen_addr_i;
                end else begin
                    v_row_ctr_d = v_row_ctr_q + 1'b1;
                    row_addr_d  = row_addr_q + h_char_displayed_i;
                end

                // Vertical display enable
                v_end = v_row_ctr_d == v_char_displayed_i;
                if (v_end) v_display_d = '0;
                else if (v_start) v_display_d = 1'b1;

                // Vertical sync
                if (v_sync_ctr_d == v_sync_width_i) v_sync_d = 1'b0;
                else if (v_row_ctr_d == v_sync_start_i) v_sync_d = 1'b1;
                else v_sync_d = v_sync_o;

                // Horizontal sync width counter
                if (v_sync_d) v_sync_ctr_d = v_sync_ctr_q + 1'b1;
                else v_sync_ctr_d = '0;
            end else begin
                v_scanline_ctr_d = ra_o + 1'b1;
            end
        end

        if (h_start) ma_d = row_addr_d;
        else ma_d = ma_o + 1'b1;
    end

    always_ff @(negedge cclk_i or posedge reset_i) begin
        if (reset_i) begin
            h_col_ctr_q      <= '0;
            h_display_q      <= 1'b1;
            h_sync_ctr_q     <= '0;
            h_sync_o         <= '0;
            ra_o             <= '0;
            v_row_ctr_q      <= '0;
            v_display_q      <= 1'b1;
            v_sync_ctr_q     <= '0;
            v_sync_o         <= '0;
            row_addr_q       <= screen_addr_i;
            ma_o             <= '0;
        end else begin
            h_col_ctr_q      <= h_col_ctr_d;
            h_display_q      <= h_display_d;
            h_sync_ctr_q     <= h_sync_ctr_d;
            h_sync_o         <= h_sync_d;
            ra_o             <= v_scanline_ctr_d;
            v_row_ctr_q      <= v_row_ctr_d;
            v_display_q      <= v_display_d;
            v_sync_ctr_q     <= v_sync_ctr_d;
            v_sync_o         <= v_sync_d;
            row_addr_q       <= row_addr_d;
            ma_o             <= ma_d;
        end
    end

    assign display_enable_o = h_display_q && v_display_q;
endmodule
