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
#include "global.h"
#include "roms.h"
#include "test.h"

const int32_t addr_min = 0x0000;
const int32_t addr_max = 0xFFFF;

void sync_display() {
    spi_write(/* dest: */ 0x8000, /* pSrc: */ video_char_buffer, /* byteLength: */ 1000);
}

void test_reset() {
    puts("Test reset");

    set_cpu(/* reset: */ true, /* run: */ false);
    sleep_ms(1);

    set_cpu(/* reset: */ false, /* run: */ false);
    sleep_ms(1);
}

uint8_t* xy(uint8_t x, uint8_t y) {
    return y * 40 + x + video_char_buffer;
}

void h_line(uint8_t start_x, uint8_t end_x, uint8_t y, uint8_t ch) {
    uint8_t* pDest = xy(start_x, y);
    uint8_t  remaining = end_x - start_x + 1;

    while (remaining--) {
        *pDest++ = ch;
    }
}

void fill(uint8_t start_x, uint8_t start_y, uint8_t end_x, uint8_t end_y, uint8_t ch) {
    for (uint8_t y = start_y; y <= end_y; y++) {
        h_line(start_x, end_x, y, ch);
    }
}

void v_line(uint8_t x, uint8_t start_y, uint8_t end_y, uint8_t ch) {
    uint8_t* pDest = xy(x, start_y);
    uint8_t  remaining = end_y - start_y + 1;

    while (remaining--) {
        *pDest = ch;
        pDest += 40;
    }
}

void set(uint8_t x, uint8_t y, uint8_t ch) {
    *xy(x, y) = ch;
}

void test_display() {
    p_video_font = p_video_font_000;
    memset(video_char_buffer, 0, sizeof(video_char_buffer));

    set(/* x: */  0, /* y: */  0, /* ch: */ 79);
    set(/* x: */ 39, /* y: */  0, /* ch: */ 80);
    set(/* x: */ 39, /* y: */ 24, /* ch: */ 122);
    set(/* x: */  0, /* y: */ 24, /* ch: */ 76);
    h_line(/* start_x: */ 1, /* end_x: */ 38, /* y: */  0, /* ch: */  99);
    h_line(/* start_x: */ 1, /* end_x: */ 38, /* y: */ 24, /* ch: */ 100);
    v_line(/* x: */  0, /* start_y: */ 1, /* end_y: */ 23, /* ch: */ 101);
    v_line(/* x: */ 39, /* start_y: */ 1, /* end_y: */ 23, /* ch: */ 103);
    fill(/* start_x: */ 1, /* start_y: */ 1, /* end_x: */ 38, /* end_y: */ 23, /* ch: */ 32);

    while (true) {
        video_char_buffer[0]++;
    };
}

void check_byte(uint32_t addr, uint8_t actual, uint8_t expected) {
    if (actual != expected) {
        printf("$%x: Expected %d, but got %d\n", addr, expected, actual);
        panic("");
    }
}

uint8_t toggle_bit(uint32_t addr, uint8_t bit, uint8_t expected) {
    spi_read_at(addr);
    uint8_t byte = spi_read_next();
    uint8_t actual = (byte >> bit) & 1;
    
    if (actual != expected) {
        printf("$%x[%d]: Expected %d, but got %d (actual byte read %x)\n", addr, bit, expected, actual, byte);
        panic("");
    }

    byte = byte ^ (1 << bit);
    spi_write_at(addr, byte);
    return byte;
}

typedef void march_element_fn(int32_t addr, int8_t bit);

void test_each_bit_ascending(march_element_fn* pFn) {
    for (int32_t addr = addr_min; addr <= addr_max; addr++) {
        for (int8_t bit = 0; bit < 8; bit++) {
            pFn(addr, bit);
        }
    }
}

void test_each_bit_descending(march_element_fn* pFn) {
    for (int32_t addr = addr_max; addr >= addr_min; addr--) {
        for (int8_t bit = 0; bit < 8; bit++) {
            pFn(addr, bit);
        }
    }
}

void r0w1(int32_t addr, int8_t bit) {
    toggle_bit(addr, bit, /* expected: */ 0);
}

void r1w0(int32_t addr, int8_t bit) {
    toggle_bit(addr, bit, /* expected: */ 1);
}

void test_ram() {
    while (true) {
        puts("Suspending CPU");

        set_cpu(/* reset: */ false, /* run: */ false);
        sleep_ms(1);

        puts("\nRAM Test (March C-):\n");

        printf("⇑(w0): ");
        spi_write_at(addr_min, 0);
        for (int32_t addr = addr_min + 1; addr <= addr_max; addr++) {
            spi_write_next(0);
        }
        puts("OK");

        printf("⇑(r0,w1): ");
        test_each_bit_ascending(r0w1);
        puts("OK");

        printf("⇑(r1,w0): ");
        test_each_bit_ascending(r1w0);
        puts("OK");

        printf("⇓(r0,w1): ");
        test_each_bit_descending(r0w1);
        puts("OK");
        
        printf("⇓(r1,w0): ");
        test_each_bit_descending(r1w0);
        puts("OK");

        printf("⇑(r0): ");
        spi_read_at(addr_min);
        for (int32_t addr = addr_min; addr <= addr_max; addr++) {
            check_byte(addr, spi_read_next(), 0);
        }
        puts("OK");
    }
}
