module address_decoding(
    input clk,
    input [16:0] addr,

    output ram_enable,
    output magic_enable,
    output pia1_enable,
    output pia2_enable,
    output via_enable,
    output crtc_enable,
    output io_enable,
    output is_mirrored,
    output is_readonly
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

    reg [8:0] select = 0;

    always @(posedge clk) begin
        select = 9'hxxx;

        casex (addr[16:0])
            17'b0_0xxx_xxxx_xxxx_xxxx: select = RAM;     // RAM   : 0000-7FFF
            17'b0_1000_xxxx_xxxx_xxxx: select = VRAM;    // VRAM  : 8000-8FFF
            17'b0_1110_1000_0000_xxxx: select = MAGIC;   // MAGIC : E800-E80F
            17'b0_1110_1000_0001_xxxx: select = PIA1;    // PIA1  : E810-E81F
            17'b0_1110_1000_001x_xxxx: select = PIA2;    // PIA2  : E820-E83F
            17'b0_1110_1000_01xx_xxxx: select = VIA;     // VIA   : E840-E87F
            17'b0_1110_1000_1xxx_xxxx: select = CRTC;    // CRTC  : E880-E8FF
            default:                   select = ROM;     // ROM   : 9000-E800, E900-FFFF
        endcase
    end

    assign ram_enable       = select[ENABLE_RAM_BIT];
    assign is_readonly      = select[IS_READONLY_BIT];
    assign is_mirrored      = select[IS_MIRRORED_BIT];

    assign magic_enable     = select[ENABLE_MAGIC_BIT];
    assign io_enable        = select[ENABLE_IO_BIT];
    assign pia1_enable      = select[ENABLE_PIA1_BIT];
    assign pia2_enable      = select[ENABLE_PIA2_BIT];
    assign via_enable       = select[ENABLE_VIA_BIT];
    assign crtc_enable      = select[ENABLE_CRTC_BIT];
endmodule