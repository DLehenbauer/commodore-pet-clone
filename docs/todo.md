# TODO

* Mfg checklist:
  * ERC
  * Check silkscreen labels
  * DRC / update copper fills
  * Review BOM (esp. look for mixed values)
  * Tag revision in Github
* HW:
  * Rotate video connector 180 degrees to match Dynamic V2 boards
  * 10uF 50V -> 10uF 25V
  * Programming
    * Combine FPGA prog and MCU debug header?
    * SPI0 already accessible elsewhere on the board, no need to expose twice.
      * Reduces FPGA pins to: TCK, TDO, TDI, TMS, ENA, SS, CRESET, GND, CDONE, NSTATUS
    * Build separate "debug PCB" that integrates:
      * Picoprobe
      * FT2232
      * Moves CDONE/NSTATUS to debug board?
  * Remove 50 MHz oscillator / use MCU instead to generate clk_sys
  * Consider LM317AG to generate +5v
    * Possibly, use second LM317AG to produce 1.5A for USB
  * Consider LM317AG to generate +1.25v (can test with spare PCB)
  * Use spare CLK/GCTL pins for signals to simplify routing
  * Expose additional unused pins
  * Tie RAM_CE to 3V3 and reclaim FPGA pin
  * Larger net ties for FPGA_*
  * Consider [SMD SRAM](https://jlcpcb.com/partdetail/444095-IS61WV1288EEBLL10TLI/C443418)
  * PIA/VIAs have multiple CS pins (with differing polarity).  Consider if other pins simplify routing or design.
* Fix signal names:
  * RD/WR_STROBE -> RAM_OE / RAM_WE
  * GRAPHICS vs. gfx
  * CPU signals (cpu_* prefix)
    * RDY vs. cpu_ready
    * SOB vs. /SO vs. so_n
    * BE vs. cpu_en
  * Video signals:
    * /VIDEO vs video (not negated)
    * vert vs v_sync
    * horiz vs h_sync
* Design
  * Try increasing SPI1 clock rate
  * Try using SPI_SCK as clock instead of oversampling
  * Explore using SPI0 to stream video to MCU in parallel
    * Possibly could bidirectionally send keyboard status at same time
  * Implement 65xx chips on FPGA to make 40-pin chips optional
