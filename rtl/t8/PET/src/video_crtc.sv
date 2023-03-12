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

module sync_gen(
    input logic       reset_i,
    input logic       clk_i,
    input logic       total_clk_en_i,
    input logic       sync_clk_en_i,

    input logic [7:0] total_i,
    input logic [7:0] displayed_i,
    input logic [7:0] sync_start_i,
    input logic [4:0] sync_width_i,     // Note: V-Sync is hardcoded to 0x10, hence 5-bit counter.

    output logic      display_o = '0,
    output logic      start_o,
    output logic      sync_o    = '0
);
    logic [7:0] counter_d, counter_q = '0;
    logic [4:0] sync_counter_d, sync_counter_q = '0;
    logic display_d;
    logic sync_d;
    logic start_d;

    always_comb begin
        // Counter & start pulse
        start_d = counter_q == total_i;
        if (start_d) counter_d = '0;
        else counter_d = counter_q + 1'b1;

        // Display enable
        if (counter_d == displayed_i) display_d = '0;
        else if (start_d) display_d = 1'b1;
        else display_d = display_o;

        // Sync pulse
        if (sync_counter_q == sync_width_i) sync_d = 1'b0;
        else if (counter_d == sync_start_i) sync_d = 1'b1;
        else sync_d = sync_o;

        // Sync width counter
        if (sync_d) sync_counter_d = sync_counter_q + 1'b1;
        else sync_counter_d = '0;
    end

    always_ff @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            counter_q      <= '0;
            display_o      <= '0;
            sync_counter_q <= '0;
            sync_o         <= '0;
        end else begin
            if (sync_clk_en_i) begin
                sync_counter_q <= sync_counter_d;
                sync_o         <= sync_d;
            end
            if (total_clk_en_i) begin
                counter_q      <= counter_d;
                display_o      <= display_d;
            end
        end
    end

    assign start_o = start_d && total_clk_en_i;
endmodule

module ra_gen(
    input  logic       reset_i,
    input  logic       clk_i,
    input  logic       line_clk_en_i,
    input  logic [4:0] row_height_i,
    output logic [4:0] ra_o         = '0,
    output logic       row_start_o
);
    logic row_start_d;
    logic [4:0] ra_d;

    always_comb begin
        row_start_d = ra_o == row_height_i;
        ra_d = row_start_d
            ? '0
            : ra_o + 1'b1;
    end

    always_ff @(posedge clk_i) begin
        if (line_clk_en_i) begin
            ra_o <= ra_d;
        end
    end

    assign row_start_o = row_start_d && line_clk_en_i;
endmodule

module ma_gen(
    input  logic        reset_i,
    input  logic        clk_i,
    input  logic        clk_en_i,
    input  logic        de_i,
    input  logic        line_start_i,
    input  logic        row_start_i,
    input  logic        frame_start_i,
    input  logic [13:0] start_addr_i,
    output logic [13:0] ma_o = '0
);
    logic [13:0] row_addr_d, row_addr_q = '0;
    logic [13:0] ma_d;

    always_comb begin
        if (frame_start_i) begin
            row_addr_d = start_addr_i;
            ma_d = start_addr_i;
        end else if (row_start_i) begin
            row_addr_d = ma_o;
            ma_d = ma_o;
        end else begin
            row_addr_d = row_addr_q;
            ma_d = line_start_i
                ? row_addr_q
                : de_i
                    ? ma_o + 1'b1
                    : ma_o;
        end
    end

    always_ff @(posedge clk_i) begin
        if (clk_en_i) begin
            row_addr_q <= row_addr_d;
            ma_o <= ma_d;
        end
    end
endmodule

module crtc(
    input  logic        reset_i,
    input  logic        strobe_clk_i,           // Triggers data transfers on bus
    input  logic        setup_clk_i,            // Triggers data transfers on bus
    input  logic        cs_i,                   // CRTC selected for data transfer (driven by address decoding)
    input  logic        rw_ni,                  // Direction of date transfers (0 = writing to CRTC, 1 = reading from CRTC)

    input  logic        rs_i,                   // Register select (0 = write address/read status, 1 = read addressed register)

    input  logic  [7:0] data_i,                 // Transfer data written from CPU to CRTC when CS asserted and /RW is low
    output logic  [7:0] data_o,                 // Transfer data read by CPU from CRTC when CS asserted and /RW is high
    output logic        data_oe,                // Asserted when CPU is reading from CRTC

    input  logic        cclk_en_i,              // Enables character clock (always 1 MHz)

    output logic        h_sync_o,               // Horizontal sync
    output logic        v_sync_o,               // Vertical sync
    output logic        de_o,                   // Display enable

    output logic [13:0] ma_o,                   // Refresh RAM address lines
    output logic  [4:0] ra_o                    // Raster address lines
);
    localparam R0_H_TOTAL           = 0,    // [7:0] Total displayed and non-displayed characters, minus one, per horizontal line.
                                            //       The frequency of HSYNC is thus determined by this register.
                
               R1_H_DISPLAYED       = 1,    // [7:0] Number of displayed characters per horizontal line.
                
               R2_H_SYNC_POS        = 2,    // [7:0] Position of the HSYNC on the horizontal line, in terms of the character location number on the line.
                                            //       The position of the HSYNC determines the left-to-right location of the displayed text on the video screen.
                                            //       In this way, the side margins are adjusted.

               R3_SYNC_WIDTH        = 3,    // [3:0] Width of HSYNC in character clock times
                                            //       (TODO: Should [7:4] control VSync?)

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
            
               R9_SCAN_LINE         = 9,    // [4:0] Number of scan lines per character row, including spacing.

               R12_DISPLAY_START_HI = 12,   // [5:0] High 6 bits of 14 bit display address (starting address of screen_addr_o[13:8]).
               R13_DISPLAY_START_LO = 13;   // [7:0] Low 8 bits of 14 bit display address (starting address of screen_addr_o[7:0]).

    logic [4:0] ar = '0;                        // Internal address register used to select R0..17
    logic [7:0] r[31:0];                        // Internal storage for R0..17 padded to next power of 2

    // CRTC drives data when the current data transfer is reading from the CRTC
    //
    // TODO:
    //  - Status register POR state should be 'x01xxxxx'
    //  - Vertical retrace status bit should fall to 0 cclk ticks before retrace ends
    //
    // (See http://archive.6502.org/datasheets/rockwell_r6545-1_crtc.pdf, pg. 3)

    assign data_oe = rw_ni && cs_i;
    assign data_o  = rs_i == '0
        ? { 2'b00, v_sync_o, 5'b0 }             // RS = 0: Read status register
        : r[ar];                                // RS = 1: Read addressed register R0..17 (TODO: Allow this?  Infers dual-port RAM?)

    initial begin
        r[R0_H_TOTAL]           = 8'd63;
        r[R1_H_DISPLAYED]       = 8'd40;
        r[R2_H_SYNC_POS]        = 8'd48;
        r[R3_SYNC_WIDTH]        = 8'h0f;
        r[R4_V_TOTAL]           = 7'd32;
        r[R5_V_LINE_ADJUST]     = 5'd00;
        r[R6_V_DISPLAYED]       = 7'd25;
        r[R7_V_SYNC_POS]        = 7'd28;
        r[R9_SCAN_LINE]         = 5'd07;
        r[R12_DISPLAY_START_HI] = 8'h10;
        r[R13_DISPLAY_START_LO] = 8'h00;
    end

    always_ff @(negedge strobe_clk_i) begin
        if (cs_i && !rw_ni) begin
            if (rs_i == '0) ar <= data_i[4:0];  // RS = 0: Write to address register
            else r[ar] <= data_i;               // RS = 1: Write to currently addressed register (R0..17)
        end
    end

    logic line_start;
    logic h_de;

    sync_gen h_sync(
        .reset_i(reset_i),
        .clk_i(setup_clk_i),
        .total_clk_en_i(cclk_en_i),             // H. total counter increments on each CCLK
        .sync_clk_en_i(cclk_en_i),              // H. sync counter increments on each CCLK
        .total_i(r[R0_H_TOTAL]),
        .displayed_i(r[R1_H_DISPLAYED]),
        .sync_start_i(r[R2_H_SYNC_POS]),
        .sync_width_i({ 1'b0, r[R3_SYNC_WIDTH][3:0] }),
        .sync_o(h_sync_o),
        .display_o(h_de),
        .start_o(line_start)
    );

    logic row_start;

    ra_gen ra_gen(
        .reset_i(reset_i),
        .clk_i(setup_clk_i),
        .line_clk_en_i(line_start),             // Line counter increments at start of scan line
        .row_height_i(5'd7),
        .ra_o(ra_o),
        .row_start_o(row_start)
    );

    logic frame_start;
    logic v_de;

    sync_gen v_sync(
        .reset_i(reset_i),
        .clk_i(setup_clk_i),
        .total_clk_en_i(row_start),             // V. total counter increments at start of character row
        .sync_clk_en_i(line_start),             // V. sync counter increments at start of scan line
        .total_i(r[R4_V_TOTAL]),
        .displayed_i(r[R6_V_DISPLAYED]),
        .sync_start_i(r[R7_V_SYNC_POS]),
        .sync_width_i(5'h10),                   // V-Sync is fixed at 16 scanlines
        .sync_o(v_sync_o),
        .display_o(v_de),
        .start_o(frame_start)
    );

    assign de_o = h_de && v_de;

    ma_gen ma_gen(
        .reset_i(reset_i),
        .clk_i(setup_clk_i),
        .clk_en_i(cclk_en_i),
        .de_i(de_o),
        .line_start_i(line_start),
        .row_start_i(row_start),
        .frame_start_i(frame_start),
        .start_addr_i({ r[R12_DISPLAY_START_HI][5:0], r[R13_DISPLAY_START_LO] }),
        .ma_o(ma_o)
    );
endmodule
