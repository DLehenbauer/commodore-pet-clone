# TODO

* HW:
  * 10uF 50V -> 10uF 25V
* FPGA:
  * Use pin 75 for address?
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
* Tie RAM_CE to 3V3 and reclaim FPGA pin
* Larger net ties for FPGA_*
* Consider [SMD SRAM](https://jlcpcb.com/partdetail/444095-IS61WV1288EEBLL10TLI/C443418)

