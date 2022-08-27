module address_decoding(
    input clk,
    input [16:0] addr,
    input rw_b,

    output ram_enable,
    output pia1_enable,
    output pia2_enable,
    output via_enable,
    output crtc_enable,
    output io_enable,
    output mirror_enable,
    output write_enable
);
    parameter ENABLE_RAM       = 1,
              ENABLE_MAGIC     = 2,
              ENABLE_PIA1      = 3,
              ENABLE_PIA2      = 4,
              ENABLE_VIA       = 5,
              ENABLE_CRTC      = 6,
              ENABLE_IO        = 7,

              PERMIT_WRITE     = 8,
              ENABLE_MIRROR    = 9;

    parameter RAM   = (1 << ENABLE_RAM)  | (1 << PERMIT_WRITE),
              VRAM  = (1 << ENABLE_RAM)  | (1 << PERMIT_WRITE) | (1 << ENABLE_MIRROR),
              MAGIC = (1 << ENABLE_RAM)  | (1 << PERMIT_WRITE),
              ROM   = (1 << ENABLE_RAM),
              PIA1  = (1 << ENABLE_PIA1) | (1 << PERMIT_WRITE) | (1 << ENABLE_IO),
              PIA2  = (1 << ENABLE_PIA2) | (1 << PERMIT_WRITE) | (1 << ENABLE_IO),
              VIA   = (1 << ENABLE_VIA)  | (1 << PERMIT_WRITE) | (1 << ENABLE_IO),
              CRTC  = (1 << ENABLE_CRTC) | (1 << PERMIT_WRITE) | (1 << ENABLE_IO);

    reg [9:0] select = 10'h0;

    always @(posedge clk) begin
        select = 8'hxx;

        casex (addr[16:0])
            17'b0_0xxx_xxxx_xxxx_xxxx: select = RAM;     // RAM   : 0000-7FFF
            17'b0_1000_xxxx_xxxx_xxxx: select = VRAM;    // VRAM  : 8000-8FFF
            17'b0_1110_1000_0000_xxxx: select = RAM;     // MAGIC : E800-E80F
            17'b0_1110_1000_0001_xxxx: select = PIA1;    // PIA1  : E810-E81F
            17'b0_1110_1000_001x_xxxx: select = PIA2;    // PIA2  : E820-E83F
            17'b0_1110_1000_01xx_xxxx: select = VIA;     // VIA   : E840-E87F
            17'b0_1110_1000_1xxx_xxxx: select = CRTC;    // CRTC  : E880-E8FF
            default:                   select = ROM;     // ROM   : 9000-E800, E900-FFFF
        endcase
    end

    assign ram_enable       = select[ENABLE_RAM];
    assign write_enable     = select[PERMIT_WRITE] & rw_b;
    assign mirror_enable    = select[ENABLE_MIRROR];

    assign io_enable        = select[ENABLE_IO];
    assign pia1_enable      = select[ENABLE_PIA1];
    assign pia2_enable      = select[ENABLE_PIA2];
    assign via_enable       = select[ENABLE_VIA];
    assign crtc_enable      = select[ENABLE_CRTC];
endmodule