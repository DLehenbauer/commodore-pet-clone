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

#pragma once

#include <stdint.h>

static const uint8_t __attribute__((aligned(4), section(".data" ".rom_chars_8800"))) rom_chars_8800[] = {
    #include "roms/characters-2.901447-10.h"
};

static const uint8_t __attribute__((aligned(4), section(".data" ".rom_basic_b000"))) rom_basic_b000[] = {
    #include "roms/basic-4-b000.901465-23.h"
};

static const uint8_t __attribute__((aligned(4), section(".data" ".rom_basic_c000"))) rom_basic_c000[] = {
    #include "roms/basic-4-c000.901465-20.h"
};

static const uint8_t __attribute__((aligned(4), section(".data" ".rom_basic_d000"))) rom_basic_d000[] = {
    #include "roms/basic-4-d000.901465-21.h"
};

static const uint8_t __attribute__((aligned(4), section(".data" ".rom_edit_e000"))) rom_edit_e000[] = {
    #include "roms/edit-4-40-n-60Hz-ntsc.h"
};

static const uint8_t __attribute__((aligned(4), section(".data" ".rom_kernal_f000"))) rom_kernal_f000[] = {
    #include "roms/kernal-4.901465-22.h"
};

static const uint8_t const* p_video_font_000 = rom_chars_8800;
static const uint8_t const* p_video_font_400 = rom_chars_8800 + 0x400;
