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

#include "pch.hpp"
#pragma once

struct RomEntry {
    const char* file;
    uint16_t addr;
    std::streamsize byteLength;
};

constexpr RomEntry charUS = { /* name: */ "characters-2.901447-10.bin", /* addr: */ 0x8800, /* byteLength: */ 0x0800 };

constexpr RomEntry basic4[] = {
    RomEntry { /* name: */ "basic-4-b000.901465-23.bin",     /* addr: */ 0xb000, /* byteLength: */ 0x1000 },
    RomEntry { /* name: */ "basic-4-c000.901465-20.bin",     /* addr: */ 0xc000, /* byteLength: */ 0x1000 },
    RomEntry { /* name: */ "basic-4-d000.901465-21.bin",     /* addr: */ 0xd000, /* byteLength: */ 0x1000 },
    RomEntry { /* name: */ "kernal-4.901465-22.bin",         /* addr: */ 0xf000, /* byteLength: */ 0x1000 },
    RomEntry { /* name: */ nullptr,                          /* addr: */ 0x0000, /* byteLength: */ 0x0000 },
};

constexpr RomEntry basic_4_edit_40col_gfx_noCRTC    = { /* name: */ "edit-4-n.901447-29.bin",         /* addr: */ 0xe000, /* byteLength: */ 0x0800 };
constexpr RomEntry basic_4_edit_40col_gfx_CRTC_60Hz = { /* name: */ "edit-4-40-n-60Hz.901499-01.bin", /* addr: */ 0xe000, /* byteLength: */ 0x0800 };
constexpr RomEntry basic_4_edit_40col_gfx_CRTC_50Hz = { /* name: */ "edit-4-40-n-50Hz.901498-01.bin", /* addr: */ 0xe000, /* byteLength: */ 0x0800 };
