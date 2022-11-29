# EP2

## Resources

* [TimeQuest User Guide](https://www.intel.com/content/dam/support/us/en/programmable/support-resources/fpga-wiki/asset02/timequest-user-guide.pdf)

## Clock In

Pin | Fn
-|-
17|50 MHz source
18|
21|
22|
88|
89|
90|
91|

## Clock Out

Pin | Pn
-|-
31|PLL1_OUTp
32|PLL1_OUTn
103|PLL2_OUTp
104|PLL2_OUTn

## Reserved

[EP2C5 Mini Dev Board](http://land-boards.com/blwiki/index.php?title=Cyclone_II_EP2C5_Mini_Dev_Board#I.2FO_Pin_Mapping)

Pin | Function | Notes
-|-|-
3 | LED D2 | Drive pin low to light LED.
7 | LED D4 | Drive pin low to light LED.
9 | LED D5 | Drive pin low to light LED.
17 | 50 MHz | Clock input from onboard oscillator.
26 | 1V2 | VCC 1.2V for EP2C8.  (See note below)
27 | GND | GND for EP2C8.  (See note below)
73 | POR | Power on reset. (10uF / 10K RC delay)
80 | GND | GND for EP2C8.  (See note below)
81 | 1V2 | VCC 1.2V for EP2C8.  (See note below)
144 | KEY | Pin low when button pressed.  Requires FPGA internal pull up.

**Note:** On EP2C5 boards pins 26, 27, 80, 81 can be used as normal if the "zero ohm" resistors are removed.
