[Picoprobe UF2 binary download](https://datasheets.raspberrypi.com/soft/picoprobe.uf2)

[Hints from ExpressIf Docs](https://github.com/espressif/vscode-esp-idf-extension/blob/HEAD/docs/tutorial/using-docker-container.md)

Install 'libusb-win32' driver for "Picoprobe (Interface 2)" using [Zadig](http://zadig.akeo.ie).

Install [usbipd](https://github.com/dorssel/usbipd-win/releases) on Windows

Install usbipd in WSL:
```
sudo apt update && \
    apt install linux-tools-5.4.0-77-generic hwdata && \
    update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/5.4.0-77-generic/usbip 20
```

From PowerShell, list devices on Windows:

```
usbipd list wsl
```

Bind 'Picoprobe':

```
usbipd bind --busid 4-2
usbipd wsl attach --busid 4-2
```

Verify attachment from WSL and from container:
```
dmesg | tail
```

Verify that you can connect to the urt with minicom:
```
sudo minicom -D /dev/ttyACM0 -b 115200
```
(If not, you probably forgot to expose the device in the container with '--device=/dev/ttyACM0')


Test that OpenOCD can connect with 'sudo':
```
sudo openocd -f interface/picoprobe.cfg -f target/rp2040.cfg -s tcl
```
(If not, you probably forgot to start the container with --privileged)

TODO: Someday figure out how to connect to Picoprobe as a non-root user:
https://elinux.org/Accessing_Devices_without_Sudo
