module address_decoding(
    input  logic [16:0] bus_addr_i,
    input  logic [16:0] spi_addr_i,

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
    localparam ENABLE_RAM_BIT   = 0,
               ENABLE_MAGIC_BIT = 1,
               ENABLE_PIA1_BIT  = 2,
               ENABLE_PIA2_BIT  = 3,
               ENABLE_VIA_BIT   = 4,
               ENABLE_CRTC_BIT  = 5,
               ENABLE_IO_BIT    = 6,
               IS_READONLY_BIT  = 7,
               IS_MIRRORED_BIT  = 8;

    localparam ENABLE_RAM_MASK   = 9'b1 << ENABLE_RAM_BIT,
               ENABLE_MAGIC_MASK = 9'b1 << ENABLE_MAGIC_BIT,
               ENABLE_PIA1_MASK  = 9'b1 << ENABLE_PIA1_BIT,
               ENABLE_PIA2_MASK  = 9'b1 << ENABLE_PIA2_BIT,
               ENABLE_VIA_MASK   = 9'b1 << ENABLE_VIA_BIT,
               ENABLE_CRTC_MASK  = 9'b1 << ENABLE_CRTC_BIT,
               ENABLE_IO_MASK    = 9'b1 << ENABLE_IO_BIT,
               IS_READONLY_MASK  = 9'b1 << IS_READONLY_BIT,
               IS_MIRRORED_MASK  = 9'b1 << IS_MIRRORED_BIT;

    localparam RAM   = ENABLE_RAM_MASK,
               VRAM  = ENABLE_RAM_MASK  | IS_MIRRORED_MASK,
               MAGIC = ENABLE_MAGIC_MASK,
               ROM   = ENABLE_RAM_MASK  | IS_READONLY_MASK,
               PIA1  = ENABLE_PIA1_MASK | ENABLE_IO_MASK,
               PIA2  = ENABLE_PIA2_MASK | ENABLE_IO_MASK,
               VIA   = ENABLE_VIA_MASK  | ENABLE_IO_MASK,
               CRTC  = ENABLE_CRTC_MASK | ENABLE_IO_MASK;

    logic [8:0] select = 9'hxxx;

    always_comb begin
        unique casez (bus_addr_i[16:0])
            17'b0_0???_????_????_????: select = RAM;     // RAM   : 0000-7FFF
            17'b0_1000_????_????_????: select = VRAM;    // VRAM  : 8000-8FFF
            17'b0_1110_1000_0000_????: select = MAGIC;   // MAGIC : E800-E80F
            17'b0_1110_1000_0001_????: select = PIA1;    // PIA1  : E810-E81F
            17'b0_1110_1000_001?_????: select = PIA2;    // PIA2  : E820-E83F
            17'b0_1110_1000_01??_????: select = VIA;     // VIA   : E840-E87F
            17'b0_1110_1000_1???_????: select = CRTC;    // CRTC  : E880-E8FF
            default:                   select = ROM;     // ROM   : 9000-E800, E900-FFFF
        endcase
    end

    assign ram_en_o       = select[ENABLE_RAM_BIT];
    assign is_readonly_o  = select[IS_READONLY_BIT];
    assign is_mirrored_o  = select[IS_MIRRORED_BIT];

    assign magic_en_o     = select[ENABLE_MAGIC_BIT];
    assign io_en_o        = select[ENABLE_IO_BIT];
    assign pia1_en_o      = select[ENABLE_PIA1_BIT];
    assign pia2_en_o      = select[ENABLE_PIA2_BIT];
    assign via_en_o       = select[ENABLE_VIA_BIT];
    assign crtc_en_o      = select[ENABLE_CRTC_BIT];
endmodule
