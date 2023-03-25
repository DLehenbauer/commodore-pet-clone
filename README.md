## PET Clone

Open hardware clone of the Commodore CBM/PET using modern parts.
Some assembly required.  :-)

![](https://github.com/DLehenbauer/commodore-pet-clone/raw/main/docs/img/assembly-required.jpg)

## Status

Working prototype.  Currently finalizing V1.0 release.

## About

This open hardware CBM/PET clone can be used in two ways:

1. By itself with an HDMI display and USB keyboard
2. As a mainboard replacement to repair/enhance a vintage CBM/PET

You can also do both at once, as shown in the image below:

![](https://github.com/DLehenbauer/commodore-pet-clone/raw/main/docs/img/status.jpg)

## Design

The following block diagram provides an overview of the system architecture:

![](https://github.com/DLehenbauer/commodore-pet-clone/raw/main/docs/img/block-diagram.drawio.svg)

Here are the highlights:

* CPU and I/O are similar to the original Commodore design, using the 6502, PIA, and VIA.
* Main RAM, Display RAM and ROM are combined on a single 128K SRAM.
  * On POR the MCU initialized $9000-FFFF with the user's selected ROM set
  * After initialization, $9000-FFFF is write protected.
* Timing, address decoding, and native PET video are consolidated on a small FPGA.
* The MCU reads display RAM and mirrors the PET video to HDMI (via bit-banged DVI)
* The MCU also reports USB keyboard input to the FPGA
  * The FPGA intercepts reads from $E812 to inject USB key input as-needed
  * When no USB keys are pressed, the read passes through to PIA1.

## Contributing

Collaborators warmly appreciated (see [Issues](https://github.com/DLehenbauer/commodore-pet-clone/issues)).

## License

This project is public domain under the CC0-1.0 license, exempting portions incorporated
from other open source projects as noted [here](NOTICE.md) and in the source code.

[![License: CC0-1.0](https://img.shields.io/github/license/DLehenbauer/commodore-pet-clone)](https://github.com/DLehenbauer/commodore-pet-clone/blob/main/LICENSE)
