module address_decoding(
    input clk,
    input [16:0] addr,

    output ram_enable,
    output pia1_enable,
    output pia2_enable,
    output via_enable,
    output crtc_enable,
    output io_enable,
    output is_mirrored,
    output is_readonly
);
    parameter ENABLE_RAM_FLAG   = 0,
              ENABLE_MAGIC_FLAG = 1,
              ENABLE_PIA1_FLAG  = 2,
              ENABLE_PIA2_FLAG  = 3,
              ENABLE_VIA_FLAG   = 4,
              ENABLE_CRTC_FLAG  = 5,
              ENABLE_IO_FLAG    = 6,
              IS_READONLY_FLAG  = 7,
              IS_MIRRORED_FLAG  = 8;

    parameter ENABLE_RAM_MASK   = 9'b1 << ENABLE_RAM_FLAG,
              ENABLE_MAGIC_MASK = 9'b1 << ENABLE_MAGIC_FLAG,
              ENABLE_PIA1_MASK  = 9'b1 << ENABLE_PIA1_FLAG,
              ENABLE_PIA2_MASK  = 9'b1 << ENABLE_PIA2_FLAG,
              ENABLE_VIA_MASK   = 9'b1 << ENABLE_VIA_FLAG,
              ENABLE_CRTC_MASK  = 9'b1 << ENABLE_CRTC_FLAG,
              ENABLE_IO_MASK    = 9'b1 << ENABLE_IO_FLAG,
              IS_READONLY_MASK  = 9'b1 << IS_READONLY_FLAG,
              IS_MIRRORED_MASK  = 9'b1 << IS_MIRRORED_FLAG;

    parameter RAM   = ENABLE_RAM_MASK,
              VRAM  = ENABLE_RAM_MASK  | IS_MIRRORED_MASK,
              MAGIC = ENABLE_RAM_MASK,
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

    assign ram_enable       = select[ENABLE_RAM_FLAG];
    assign is_readonly      = select[IS_READONLY_FLAG];
    assign is_mirrored      = select[IS_MIRRORED_FLAG];

    assign io_enable        = select[ENABLE_IO_FLAG];
    assign pia1_enable      = select[ENABLE_PIA1_FLAG];
    assign pia2_enable      = select[ENABLE_PIA2_FLAG];
    assign via_enable       = select[ENABLE_VIA_FLAG];
    assign crtc_enable      = select[ENABLE_CRTC_FLAG];
endmodule