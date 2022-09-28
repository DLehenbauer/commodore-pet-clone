# Pico Debugging

## Share Picoprobe with WSL

```sh
usbipd wsl attach --hardware-id 2e8a:0004
```

## Listen to UART

```sh
minicom -b 115200 -o -D /dev/ttyACM0
```
