//`ifndef _CRTC_VH_
//`define _CRTC_VH_

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

//`endif // _CRTC_VH_
