# TODO

* Mfg checklist:
  * ERC
  * Check silkscreen labels
  * DRC / update copper fills
  * Review BOM (esp. look for mixed values)
  * Tag revision in Github
* HW:
  * Clean up SPI:
    * Routing
    * 25k pullups for SD card?
    * Reverse SPI1?  (Recall that SPI is fastest when RP2040 drives clk)
  * Consider FPGA UART
  * Programming
    * Build separate "debug PCB" that integrates:
      * Picoprobe
      * FT2232
      * Moves CDONE/NSTATUS to debug board?
  * Larger net ties for FPGA_*
  * Consider [SMD SRAM](https://jlcpcb.com/partdetail/444095-IS61WV1288EEBLL10TLI/C443418)
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
