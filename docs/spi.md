# SPI

RP2040 maximum SPI speed is 24 MBd (controller).

## SPI1

### Handshake

* MCU waits for FPGA to assert READY
* MCU asserts CS (resets FSM)
* MCU transmits bytes
* MCU waits for FPGA to assert READY
* MCU deasserts CS
