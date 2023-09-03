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

module address_decoding(
    input  logic [16:0] addr_i,

    output logic ram_en_o,
    output logic magic_en_o,
    output logic pia1_en_o,
    output logic pia2_en_o,
    output logic via_en_o,
    output logic crtc_en_o,
    output logic io_en_o,
    output logic is_mirrored_o,
    output logic is_readonly_o
);
    localparam NUM_BITS         = 9;

    localparam RAM_EN_BIT       = 0,
               MAGIC_EN_BIT     = 1,
               PIA1_EN_BIT      = 2,
               PIA2_EN_BIT      = 3,
               VIA_EN_BIT       = 4,
               CRTC_EN_BIT      = 5,
               IO_EN_BIT        = 6,
               RAM_READONLY_BIT = 7,
               RAM_MIRRORED_BIT = 8;

    localparam RAM_EN_MASK       = NUM_BITS'(1'b1) << RAM_EN_BIT,
               MAGIC_EN_MASK     = NUM_BITS'(1'b1) << MAGIC_EN_BIT,
               PIA1_EN_MASK      = NUM_BITS'(1'b1) << PIA1_EN_BIT,
               PIA2_EN_MASK      = NUM_BITS'(1'b1) << PIA2_EN_BIT,
               VIA_EN_MASK       = NUM_BITS'(1'b1) << VIA_EN_BIT,
               CRTC_EN_MASK      = NUM_BITS'(1'b1) << CRTC_EN_BIT,
               IO_EN_MASK        = NUM_BITS'(1'b1) << IO_EN_BIT,
               RAM_READONLY_MASK = NUM_BITS'(1'b1) << RAM_READONLY_BIT,
               RAM_MIRRORED_MASK = NUM_BITS'(1'b1) << RAM_MIRRORED_BIT;

    localparam RAM   = RAM_EN_MASK,
               VRAM  = RAM_EN_MASK  | RAM_MIRRORED_MASK,
               MAGIC = MAGIC_EN_MASK,
               ROM   = RAM_EN_MASK  | RAM_READONLY_MASK,
               PIA1  = PIA1_EN_MASK | IO_EN_MASK,
               PIA2  = PIA2_EN_MASK | IO_EN_MASK,
               VIA   = VIA_EN_MASK  | IO_EN_MASK,
               CRTC  = CRTC_EN_MASK;                    // No IO_EN: CRTC implemented on FPGA

    logic [NUM_BITS-1:0] select = NUM_BITS'('hxxx);

    always_comb begin
        priority casez (addr_i[16:0])
            17'b0_0???_????_????_????: select = RAM;    // RAM   : 0000-7FFF
            17'b0_1000_????_????_????: select = VRAM;   // VRAM  : 8000-8F00
            17'b0_1110_1000_0000_????: select = MAGIC;  // MAGIC : E800-E80F
            17'b0_1110_1000_0001_????: select = PIA1;   // PIA1  : E810-E81F
            17'b0_1110_1000_001?_????: select = PIA2;   // PIA2  : E820-E83F
            17'b0_1110_1000_01??_????: select = VIA;    // VIA   : E840-E87F
            17'b0_1110_1000_1???_????: select = CRTC;   // CRTC  : E880-E8FF
            default:                   select = ROM;    // ROM   : 9000-E800, E900-FFFF
        endcase
    end

    assign ram_en_o       = select[RAM_EN_BIT];
    assign is_readonly_o  = select[RAM_READONLY_BIT];
    assign is_mirrored_o  = select[RAM_MIRRORED_BIT];

    assign magic_en_o     = select[MAGIC_EN_BIT];
    assign io_en_o        = select[IO_EN_BIT];
    assign pia1_en_o      = select[PIA1_EN_BIT];
    assign pia2_en_o      = select[PIA2_EN_BIT];
    assign via_en_o       = select[VIA_EN_BIT];
    assign crtc_en_o      = select[CRTC_EN_BIT];
endmodule
