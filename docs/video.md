# Video

## Non-CRTC Timing

Measurements from a 2001-32N (1979):

Signal | Frequency  | Source
-------|------------|----------
Crystal| 16.007 MHz | I1 pin 1
CPU    | 1.0009 MHz | 6502 pin 37
HSync  | 15.63 KHz  | Video pin 5 (consistent with 16.007 MHz / 1024 = 15.632 KHz)
VSync  | 60.12 Hz   | Video pin 3 (consistent with 15.632 KHz / 260 lines = ~60.122 Hz)

Closest CRTC settings:

Register | Value | Description
---------|-------|-----------------------------------------------
 R0      |   63  | H_TOTAL = 8 MHz pixel clock / 8 pixel char / (64 chars - 1) = 15.625 KHz
 R1      |   40  | H_DISPLAYED = 40 columns
 R2      |   48  | H_SYNC_POS
 R3[3:0] |    1  | H_SYNC_WIDTH = 1
 R3[7:4] |    5  | V_SYNC_WIDTH = 5
 R4      |   32  | V_TOTAL = 15.625 KHz / ((33 rows - 1) * 8 lines per row) = 61.04 Hz
 R5      |    5  | V_LINE_ADJUST = 15.625 KHz / (33 rows * 8 lines per row + 5 lines) = 60.10 Hz
 R6      |   25  | V_DISPLAYED = 25 rows
 R7      |   28  | V_SYNC_POS
 R9      |    7  | SCAN_LINE = 8 pixel character height (-1)

Current CRTC bugs:

* V_TOTAL should be minus one (currently 33 => 59Hz)
* V_LINE_ADJUST not implemented
* Sync width of 0 unverified?

## Tools

* [VGA Timing Calculator](https://www.epanorama.net/faq/vga2rgb/calc.html)
* [Pixel Clock Calculator](https://www.monitortests.com/pixelclock.php)

## Reference

* VGA
  * [VGA Timings](http://martin.hinner.info/vga/timing.html)
  * [TinyVGA Timings](http://www.tinyvga.com/vga-timing)
* DVI
  * [CEA-861-D](https://ia903002.us.archive.org/1/items/CEA-861-D/CEA-861-D.pdf)
* NTSC / PAL
  * [Timing Characteristics](http://www.kolumbus.fi/pami1/video/pal_ntsc.html)
* CRTC
  * [Operation](http://www.6502.org/users/andre/hwinfo/crtc/crtc.html)
  * [Internals](http://www.6502.org/users/andre/hwinfo/crtc/internals/index.html)
  * [Wikipedia](https://en.wikipedia.org/wiki/Motorola_6845)
  * [Register Values](https://github.com/sjgray/cbm-edit-rom/blob/master/docs/CRTC%20Registers.txt)
  * Datasheet
    * [Rockwell R6545](http://archive.6502.org/datasheets/rockwell_r6545-1_crtc.pdf)
    * [Motorolla MC6845](http://m.www.datasheets.pl/elementy_czynne/IC/MC6845.pdf)
    * [C6845 CRT Controller IP](https://colorcomputerarchive.com/repo/Documents/Datasheets/SY6845E-C6845%20CRT%20Controller%20(CAST).pdf)
