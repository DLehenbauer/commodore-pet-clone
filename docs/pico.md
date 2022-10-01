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
