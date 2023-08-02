# Pico Debugging

Used ExpressIf directions
[Outdated setup for WSL2](https://github.com/robotdad/piconotes)

Setup:

* Flash Pico with the [Picoprobe UF2 file](https://www.raspberrypi.com/documentation/microcontrollers/raspberry-pi-pico.html#debugging-using-another-raspberry-pi-pico).

## Share Picoprobe with WSL

```sh
usbipd wsl attach --hardware-id 2e8a:0004
```

## Listen to UART

```sh
minicom -b 115200 -o -D /dev/ttyACM0
```

## Specs

* [Device Class Definition for Human Interface Devices (HID)](https://www.usb.org/sites/default/files/hid1_11.pdf)
* [HID Usage Tables](https://usb.org/sites/default/files/hut1_3_0.pdf)
* [Pinout](https://pico.pinout.xyz/)

## CMD

7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
-|-|-|-|-|-|-|-
 LEN[2] | LEN[1] | LEN[0] | x | x | x | RW_B | A16

CMD        |          binary             |      hex
-----------|-----------------------------|-----------------
READ_AT    | { 7'b011_xxx_1, addr[16] }  |
READ_NEXT  | { 8'b001_xxx_1_x            |
WRITE_AT   | { 7'b100_xxx_0, addr[16] }  |
