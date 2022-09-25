#include <stdio.h>
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/spi.h"

#define PENDING_B_PIN 6
#define DONE_B_PIN 7

#define SPI_INSTANCE spi0
#define SPI_SCK_PIN 2
#define SPI_TX_PIN 3
#define SPI_RX_PIN 4
#define SPI_CSN_PIN 5

volatile uint32_t success = 0;

const uint8_t rom_chars_8800[] = {
    #include "roms/characters-2.901447-10.h"
};

const uint8_t rom_basic_b000[] = {
    #include "roms/basic-4-b000.901465-23.h"
};

const uint8_t rom_basic_c000[] = {
    #include "roms/basic-4-c000.901465-20.h"
};

const uint8_t rom_basic_d000[] = {
    #include "roms/basic-4-d000.901465-21.h"
};

const uint8_t rom_edit_e000[] = {
    #include "roms/edit-4-40-n-60Hz-ntsc.h"
};

const uint8_t rom_kernal_f000[] = {
    #include "roms/kernal-4.901465-22.h"
};

void pi_write(uint16_t addr, uint8_t data) {
    uint8_t addr_hi = addr >> 8;
    uint8_t addr_lo = addr & 0xff;

    uint8_t bytes [] = { 0x00, addr_hi, addr_lo, data };

    gpio_put(PENDING_B_PIN, 0);
    while(!gpio_get(DONE_B_PIN));

    spi_write_blocking(SPI_INSTANCE, bytes, sizeof(bytes));
    
    // Wait for the Pi to respond
    while(gpio_get(DONE_B_PIN));
    gpio_put(PENDING_B_PIN, 1);

    success++;
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

    spi_init(SPI_INSTANCE, /* 1 MHz */ 1000 * 1000);
    gpio_set_function(SPI_SCK_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_TX_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_RX_PIN, GPIO_FUNC_SPI);
    gpio_set_function(SPI_CSN_PIN, GPIO_FUNC_SPI);

    set_cpu(/* reset: */ true, /* run: */ false);
    set_cpu(/* reset: */ false, /* run: */ true);

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

int main() {
    init();

    while (true) {
        sleep_ms(10000);
    }

    return 0;
}
