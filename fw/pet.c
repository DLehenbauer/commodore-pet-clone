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
#include "pet.h"
#include "roms.h"

void pet_reset() {
    set_cpu(/* reset: */ true, /* run: */ false);
    set_cpu(/* reset: */ false, /* run: */ false);

    spi_write(/* dest: */ 0x8800, /* pSrc: */ rom_chars_8800,  sizeof(rom_chars_8800));
    spi_write(/* dest: */ 0xb000, /* pSrc: */ rom_basic_b000,  sizeof(rom_basic_b000));
    spi_write(/* dest: */ 0xc000, /* pSrc: */ rom_basic_c000,  sizeof(rom_basic_c000));
    spi_write(/* dest: */ 0xd000, /* pSrc: */ rom_basic_d000,  sizeof(rom_basic_d000));
    spi_write(/* dest: */ 0xe000, /* pSrc: */ rom_edit_e000,   sizeof(rom_edit_e000));
    spi_write(/* dest: */ 0xf000, /* pSrc: */ rom_kernal_f000, sizeof(rom_kernal_f000));

    // Reset and resume CPU
    set_cpu(/* reset: */ true, /* run: */ false);
    set_cpu(/* reset: */ false, /* run: */ true);
}

void pet_main() {
    while (true) {
        // Dispatch TinyUSB events
        tuh_task();

        spi_write(/* dest */ 0xe800, /* pSrc: */ key_matrix, /* byteLength: */ sizeof(key_matrix));
        spi_read(/* pDest: */ video_char_buffer, /* src: */ 0x8000, /* byteLength: */ 1000);
    }
}
