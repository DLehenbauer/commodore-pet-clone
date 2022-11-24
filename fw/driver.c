/**
 * PET Clone - Open hardware implementation of the Commodore PET
 * by Daniel Lehenbauer and contributors.
 * 
 * https://github.com/DLehenbauer/commodore-pet-clone
 *
 * To the extent possible under law, I, Daniel Lehenbauer, have waived all
 * copyright and related or neighboring rights to this project. This work is
 * published from the United States.
 *
 * @copyright CC0 http://creativecommons.org/publicdomain/zero/1.0/
 * @author Daniel Lehenbauer <DLehenbauer@users.noreply.github.com> and contributors
 */

#include "driver.h"

#define CPU_RESB_PIN 28
#define READY_B_PIN 7

#define SPI_INSTANCE spi0
#define SPI_SCK_PIN 2
#define SPI_TX_PIN 3
#define SPI_RX_PIN 4
// #define SPI_CSN_PIN 5
#define SPI_CSN_PIN 6

void cpu_reset() {
    gpio_set_dir(CPU_RESB_PIN, GPIO_OUT);
    gpio_put(CPU_RESB_PIN, 0);
    sleep_ms(1);
    gpio_set_dir(CPU_RESB_PIN, GPIO_IN);
}

#define SPI_CMD_READ_AT    0xC0
#define SPI_CMD_READ_NEXT  0x80
#define SPI_CMD_WRITE_AT   0x40
#define SPI_CMD_WRITE_NEXT 0x00

void driver_init() {
    gpio_set_dir(CPU_RESB_PIN, GPIO_IN);

    // To save an IO pin, we use CS_N to frame multibyte commands.  This requires us to
    // drive CS_N from software since RP2040's hardware CS_N deasserts between bytes.
    //
    // Therefore we configure SPI_CSN_PIN as GPIO_OUT rather than GPIO_FUNC_SPI.
    //
    // (See https://github.com/raspberrypi/pico-sdk/issues/88)
    gpio_init(SPI_CSN_PIN);
    gpio_set_dir(SPI_CSN_PIN, GPIO_OUT);
    gpio_put(SPI_CSN_PIN, 1);
    sleep_ms(1);
    
    gpio_init(READY_B_PIN);
    gpio_set_dir(READY_B_PIN, GPIO_IN);

    spi_init(SPI_INSTANCE, /* 8 MHz */ 8 * 1000 * 1000);
    gpio_set_function(SPI_SCK_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_TX_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_RX_PIN, GPIO_FUNC_SPI);
}

void cmd_start() {
    while (!gpio_get(READY_B_PIN));
    gpio_put(SPI_CSN_PIN, 0);
}

void cmd_end() {
    while (gpio_get(READY_B_PIN));
    gpio_put(SPI_CSN_PIN, 1);
}


uint8_t spi_read_at(uint32_t addr) {
    const uint8_t cmd = SPI_CMD_READ_AT | addr >> 16;
    const uint8_t addr_hi = addr >> 8;
    const uint8_t addr_lo = addr & 0xff;
    const uint8_t tx[] = { cmd, addr_hi, addr_lo };

    cmd_start();
    spi_write_blocking(SPI_INSTANCE, tx, sizeof(tx));
    cmd_end();
}

uint8_t spi_read_next() {
    const uint8_t tx[1] = { SPI_CMD_READ_NEXT };
    uint8_t rx[sizeof(tx)];

    cmd_start();
    spi_write_read_blocking(spi_default, tx, rx, sizeof(tx));
    cmd_end();
    
    return rx[0];
}

void spi_read(uint8_t* pDest, uint32_t src, uint32_t byteLength) {
    spi_read_at(src);

    while (byteLength--) {
        *pDest++ = spi_read_next();
    }
}

void spi_write_at(uint32_t addr, uint8_t data) {
    const uint8_t cmd = SPI_CMD_WRITE_AT | addr >> 16;
    const uint8_t addr_hi = addr >> 8;
    const uint8_t addr_lo = addr & 0xff;
    const uint8_t tx [] = { cmd, data, addr_hi, addr_lo };

    cmd_start();
    spi_write_blocking(SPI_INSTANCE, tx, sizeof(tx));
    cmd_end();

    // uint8_t actual = spi_read_at(addr);
    // if (actual != data) {
    //     printf("$%04x: Expected $%02x, but got $%02x\n", addr, data, actual);
    //     panic(0);
    // }
}

void spi_write_next(uint8_t data) {
    const uint8_t tx [] = { SPI_CMD_WRITE_NEXT, data };

    cmd_start();
    spi_write_blocking(SPI_INSTANCE, tx, sizeof(tx));
    cmd_end();
    
    // uint8_t actual = spi_read_at(addr);
    // if (actual != data) {
    //     printf("$%04x: Expected $%02x, but got $%02x\n", addr, data, actual);
    //     panic(0);
    // }
}

void spi_write(uint32_t dest, const uint8_t const* pSrc, uint32_t byteLength) {
    const uint8_t* p = pSrc;
    
    if (byteLength--) {
        spi_write_at(dest, *p++);

        while (byteLength--) {
            spi_write_next(*p++);
        }
    }
}

void set_cpu(bool reset, bool run) {
    spi_write_at(0xE80F,
        (reset ? 0 : (1 << 0))          // res_b
        | (run ? (1 << 1) : 0));        // rdy
    
    sleep_ms(1);
}
