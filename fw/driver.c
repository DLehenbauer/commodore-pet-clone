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
#include "hw.h"

#define SPI_CMD_READ_AT    0xC0
#define SPI_CMD_READ_NEXT  0x80
#define SPI_CMD_WRITE_AT   0x40
#define SPI_CMD_WRITE_NEXT 0x00

void driver_init() {
    // Configure SPI_CS_N_PIN as GPIO_OUT rather than GPIO_FUNC_SPI because the RP2040's
    // hardware CS_N deasserts between bytes and our design relies on CS_N being held low
    // to frame multibyte commands transmitted to the FPGA.
    //
    // (See https://github.com/raspberrypi/pico-sdk/issues/88)

    gpio_init(SPI_CSN_PIN);
    gpio_set_dir(SPI_CSN_PIN, GPIO_OUT);
    gpio_put(SPI_CSN_PIN, 1);

    // In case the MCU is reset mid-transmission, Hold CS_N high long enough to trigger a
    // synchronous reset of the FPGA's state machine so it is ready for a new command.
    sleep_ms(1);
    
    gpio_init(SPI_READY_B_PIN);
    gpio_set_dir(SPI_READY_B_PIN, GPIO_IN);

    uint baudrate = spi_init(SPI_INSTANCE, SPI_MHZ * 1000 * 1000);
    gpio_set_function(SPI_SCK_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_TX_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_RX_PIN, GPIO_FUNC_SPI);

    printf("    spi1     = %d Bd\n", baudrate);
}

void cmd_start() {
    while (!gpio_get(SPI_READY_B_PIN));
    gpio_put(SPI_CSN_PIN, 0);
}

void cmd_end() {
    while (gpio_get(SPI_READY_B_PIN));
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
    spi_write_read_blocking(SPI_INSTANCE, tx, rx, sizeof(tx));
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
}

void spi_write_next(uint8_t data) {
    const uint8_t tx [] = { SPI_CMD_WRITE_NEXT, data };

    cmd_start();
    spi_write_blocking(SPI_INSTANCE, tx, sizeof(tx));
    cmd_end();
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
