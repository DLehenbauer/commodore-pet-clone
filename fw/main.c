#include "pch.h"
#include "global.h"
#include "roms.h"
#include "usb/usb.h"
#include "dvi/dvi.h"

#define PENDING_B_PIN 6
#define DONE_B_PIN 7

#define SPI_INSTANCE spi0
#define SPI_SCK_PIN 2
#define SPI_TX_PIN 3
#define SPI_RX_PIN 4
#define SPI_CSN_PIN 5

uint8_t pi_read_next() {
    const uint8_t tx[1] = { 0x22 };
    uint8_t rx[sizeof(tx)];

    while(!gpio_get(DONE_B_PIN));
    gpio_put(PENDING_B_PIN, 0);

    spi_write_read_blocking(spi_default, tx, rx, sizeof(tx));
    
    while(gpio_get(DONE_B_PIN));
    gpio_put(PENDING_B_PIN, 1);

    return rx[0];
}

uint8_t pi_read(uint16_t addr) {
    const uint8_t addr_hi = addr >> 8;
    const uint8_t addr_lo = addr & 0xff;
    const uint8_t tx[] = { 0x66, addr_hi, addr_lo };

    while(!gpio_get(DONE_B_PIN));
    gpio_put(PENDING_B_PIN, 0);

    spi_write_blocking(SPI_INSTANCE, tx, sizeof(tx));
    
    while(gpio_get(DONE_B_PIN));
    gpio_put(PENDING_B_PIN, 1);

    return pi_read_next();
}

void pi_write(uint16_t addr, uint8_t data) {
    const uint8_t addr_hi = addr >> 8;
    const uint8_t addr_lo = addr & 0xff;
    const uint8_t tx [] = { 0x84, data, addr_hi, addr_lo };

    while(!gpio_get(DONE_B_PIN));
    gpio_put(PENDING_B_PIN, 0);

    spi_write_blocking(SPI_INSTANCE, tx, sizeof(tx));
    
    while(gpio_get(DONE_B_PIN));
    gpio_put(PENDING_B_PIN, 1);

    uint8_t actual = pi_read(addr);
    if (actual != data) {
        printf("$%04x: Expected $%02x, but got $%02x\n", addr, data, actual);
        panic(0);
    }
}

void set_cpu(bool reset, bool run) {
    pi_write(0xE80F,
        (reset ? 0 : (1 << 0))          // res_b
        | (run ? (1 << 1) : 0));        // rdy
    
    sleep_ms(1);
}

void copy_rom(const uint8_t const* pRom, uint16_t start, uint16_t byteLength) {
    const uint8_t* pSrc = pRom;
    int end = start + byteLength;
    for (int addr = start; addr < end; addr++) {
        pi_write(addr, *pSrc++);
    }
}

void init() {
    stdio_init_all();

    gpio_init(PENDING_B_PIN);
    gpio_set_dir(PENDING_B_PIN, GPIO_OUT);
    gpio_put(PENDING_B_PIN, 1);
    sleep_ms(1);
    
    gpio_init(DONE_B_PIN);
    gpio_set_dir(DONE_B_PIN, GPIO_IN);

    spi_init(SPI_INSTANCE, /* 2 MHz */ 2000 * 1000);
    gpio_set_function(SPI_SCK_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_TX_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_RX_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_CSN_PIN, GPIO_FUNC_SPI);

    set_cpu(/* reset: */ true, /* run: */ false);
    set_cpu(/* reset: */ false, /* run: */ false);

    copy_rom(rom_chars_8800,  0x8800, sizeof(rom_chars_8800));
    copy_rom(rom_basic_b000,  0xb000, sizeof(rom_basic_b000));
    copy_rom(rom_basic_c000,  0xc000, sizeof(rom_basic_c000));
    copy_rom(rom_basic_d000,  0xd000, sizeof(rom_basic_d000));
    copy_rom(rom_edit_e000,   0xe000, sizeof(rom_edit_e000));
    copy_rom(rom_kernal_f000, 0xf000, sizeof(rom_kernal_f000));

    // Reset and resume CPU
    set_cpu(/* reset: */ true, /* run: */ false);
    set_cpu(/* reset: */ false, /* run: */ true);
}

int __not_in_flash("main") main() {
    init();
    usb_init();
    video_init(rom_chars_8800);

    while (true) {
        // Dispatch TinyUSB events
        tuh_task();

        for (uint8_t row = 0; row < sizeof(key_matrix); row++) {
            pi_write(0xe800 + row, key_matrix[row]);
        }
    }

    __builtin_unreachable();
}
