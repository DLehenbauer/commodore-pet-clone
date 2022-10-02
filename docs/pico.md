# Pico Debugging

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

## CMD

7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
-|-|-|-|-|-|-|-
 LEN[2] | LEN[1] | LEN[0] | x | x | SET_ADDR | RW_B | A16

CMD        |          binary             |      hex
-----------|-----------------------------|-----------------
READ_AT    | 8'b011_xx_1_1_x             |
READ_NEXT  | 8'b001_xx_0_1_x             |
WRITE_AT   | { 7'b100_xx_1_0, addr[16] } | 0x84 + A16
WRITE_NEXT | 8'b010_xx_0_0_x             |
