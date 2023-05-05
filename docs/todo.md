# TODO

* Mfg checklist:
  * ERC
  * Check silkscreen labels
  * DRC / update copper fills
  * Review BOM (esp. look for mixed values)
  * Tag revision in Github
* HW:
  * Expose RES on lower header
  * Use 4:16 decoder for keyboard expansion (C21061)
    * See http://www.6502.org/users/sjgray/projects/petkeyboard/index.html
  * 10uF 50V -> 10uF 25V
  * Programming
    * Combine FPGA prog and MCU debug header?
    * SPI0 already accessible elsewhere on the board, no need to expose twice.
      * Reduces FPGA pins to: TCK, TDO, TDI, TMS, ENA, SS, CRESET, GND, CDONE, NSTATUS
    * Build separate "debug PCB" that integrates:
      * Picoprobe
      * FT2232
      * Moves CDONE/NSTATUS to debug board?
  * Use second LM317AG to produce 1.5A for USB or reduce USB PD resistors
  * Use spare CLK/GCTL pins for signals to simplify routing
  * Expose additional unused pins
  * Larger net ties for FPGA_*
  * Consider [SMD SRAM](https://jlcpcb.com/partdetail/444095-IS61WV1288EEBLL10TLI/C443418)
  * PIA/VIAs have multiple CS pins (with differing polarity).  Consider if other pins simplify routing or design.
  * Avoid CBSEL0 for dip switch as these effect boot image.
  * Align reference designators with original PET?
* Fix signal names:
  * RD/WR_STROBE -> RAM_OE / RAM_WE
  * GRAPHICS vs. gfx
  * CPU signals (cpu_* prefix)
    * RDY vs. cpu_ready
    * SOB vs. /SO vs. so_n
    * BE vs. cpu_en
  * Video signals:
    * vert vs v_sync
    * horiz vs h_sync
* Design
  * Try increasing SPI1 clock rate
  * Try using SPI_SCK as clock instead of oversampling
  * Explore using SPI0 to stream video to MCU in parallel
    * Possibly could bidirectionally send keyboard status at same time
  * Implement 65xx chips on FPGA to make 40-pin chips optional
