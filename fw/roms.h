#pragma once

#include <stdint.h>

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
