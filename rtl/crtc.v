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

// Simple H/V sync generator @60 Hz.
module hvSync(
    input clk16,
    output hsync,
    output vsync
);
    reg [18:0] count = 0;
    
    // Bits 9:0 divide 16 MHz 'clk' by 1024 to get the HSync frequency of ~15.6 KHz
    assign hsync = count[9];

    // Bits 18:10 count horizontal scan lines.  Bit 18 is high only momentarily before
    // we reach line 260 and reset the counter.  Therefore we use bit 17 to get a 60 Hz
    // VSync with a duty cycle of ~49.2%.
    
    localparam VBLANK = (19'd260 << 10);
    
    assign vsync = count[17];
    
    always @(posedge clk16) begin
        if (count != (VBLANK - 1)) count <= count + 19'd1;
        else count <= 0;
    end
endmodule

 
module crtc(
    input  cclk,                    // 1 MHz Character Clock
    input     [16:0] bus_addr,
    input      [7:0] data_in,
    input     [15:0] pi_addr,
    output reg [7:0] data_out,
    input  res_b,
    input  read_strobe,
    input  write_strobe,
    input  crtc_select,
    output reg hsync,
    output vsync
);
    reg [5:0] status = 0;
    reg [7:0] r [16:0];

    // CCLK cycle #   0000000000111111 .... 3333344444444445555555555
    //                0123456789012345 .... 5678901234567890123456789
    //                 _________________  _______
    // Display Enable_|                          |___________________|
    //                                           ^ R1 = 40           ^ R0 = 59
    //                                                 _______
    // HSync          __________________  ____________|       |______
    // 
    //                                                <-------> R3 = 8
    //                                                ^
    //                                                 R2 = 45

    localparam R0_H_TOTAL      = 0,          // [7:0] Total displayed and non-displayed characters, minus one, per horizontal line.
                                             //       The frequency of HSYNC is thus determined by this register.
              
               R1_H_DISPLAYED  = 1,          // [7:0] Number of displayed characters per horizontal line.
              
               R2_H_SYNC_POS   = 2,          // [7:0] Position of the HSYNC on the horizontal line, in terms of the character location number on the line.
                                             //       The position of the HSYNC determines the left-to-right location of the displayed text on the video screen.
                                             //       In this way, the side margins are adjusted.

               R3_H_AND_V_SYNC_WIDTH = 3,    // [7:4] Width of VSYNC in scan lines
                                             // [3:0] Width of HSYNC in character clock times

               R4_V_TOTAL = 4,               // [6:0] Total number of character rows in a frame, minus one. This register, along with R5,
                                             //       determines the overall frame rate, which should be close to the line frequency to
                                             //       ensure flicker-free appearance. If the frame time is adjusted to be longer than the
                                             //       period of the line frequency, then /RES may be used to provide absolute synchronism.

               R5_V_TOTAL_ADJUST = 5,        // [4:0] Number of additional scan lines needed to complete an entire frame scan and is intended
                                             //       as a fine adjustment for the video frame time.

               R6_V_DISPLAYED = 6,           // [6:0] Number of displayed character rows in each frame. In this way, the vertical size of the
                                             //       displayed text is determined.
            
               R7_V_SYNC_POS = 7,            // [6:0] Selects the character row time at which the VSYNC pulse is desired to occur and, thus,
                                             //       is used to position the displayed text in the vertical direction.
            
               R9_SCAN_LINE = 9;             // [4:0] Number of scan lines per character row, including spacing.

    reg [7:0] h_front;
    reg [7:0] h_sync;
    reg [7:0] h_back;
    reg [7:0] h_reset;

    always @(negedge write_strobe or negedge res_b) begin
        if (!res_b) begin
            r[0] = 8'h31;
            r[1] = 8'h28;
            r[2] = 8'h29;
            r[3] = 8'h0f;
            r[4] = 8'h28;
            r[5] = 8'h05;
            r[6] = 8'h19;
            r[7] = 8'h21;
            r[8] = 8'h00;
            r[9] = 8'h07;
            r[10] = 8'h00;
            r[11] = 8'h00;
            r[12] = 8'h10;
            r[13] = 8'h00;
            r[14] = 8'h00;
            r[15] = 8'h00;
            r[16] = 8'h00;

            h_front <= r[R1_H_DISPLAYED];
            h_sync  <= r[R2_H_SYNC_POS];
            h_back  <= r[R2_H_SYNC_POS] + r[R3_H_AND_V_SYNC_WIDTH][3:0];
            h_reset <= r[R0_H_TOTAL];
        end else if (crtc_select) begin
            // 'crtc_select' is high when the bus address is in the $E8xx range.  Even addresses
            // map to CRTC register 0 and odd addresses are CRTC register 1.
            if (bus_addr[0] == 0)
                status <= data_in[5:0];
            else
                r[status] <= data_in;

            h_front <= r[R1_H_DISPLAYED];
            h_sync  <= r[R2_H_SYNC_POS];
            h_back  <= r[R2_H_SYNC_POS] + r[R3_H_AND_V_SYNC_WIDTH][3:0];
            h_reset <= r[R0_H_TOTAL];
        end
    end
    
    always @(posedge read_strobe) begin
        data_out <= r[pi_addr[4:0]];
    end

    reg [7:0] horiz = 0;
    reg [3:0] hSyncCnt = 0;
    wire endOfLine = horiz == h_reset;

    always @(posedge cclk) begin
        if (endOfLine) begin
            horiz <= 0;
        end else begin
            horiz <= horiz + 8'd1;
        end

        if (horiz == h_sync) begin
            hsync <= 1;
        end else begin
            hsync <= 0;
        end
    end

    reg [4:0] charRasterLine = 0;
    reg [7:0] charTextLine = 0;

    always @(posedge endOfLine) begin
        if (charRasterLine == r[R9_SCAN_LINE]) begin
            charRasterLine <= 0;
            if (charTextLine == r[R4_V_TOTAL]) charTextLine <= 0;
            else charTextLine <= charTextLine + 7'd1;
        end
        else charRasterLine <= charRasterLine + 5'd1;
    end

    assign vsync = charTextLine == r[R4_V_TOTAL];
endmodule