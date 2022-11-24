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
#include "test.h"

void sync_display() {
    spi_write(/* dest: */ 0x8000, /* pSrc: */ video_char_buffer, /* byteLength: */ 1000);
}

void test_init() {
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

    char_test(2, 2);

    sync_display();

    while (true) {
        video_char_buffer[0]++;
        sync_display();
    };
}
