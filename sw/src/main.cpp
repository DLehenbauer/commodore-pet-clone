/**
 * PET Clone - Open hardware implementation of the Commodore PET
 * by Daniel Lehenbauer (and contributors).
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
#include "display.hpp"
#include "driver.hpp"
#include "gpio.hpp"
#include "roms.hpp"
#include "trace.hpp"

uint8_t memory[0x10000] = { 0 };
uint8_t charRomPage = 1;

constexpr uint16_t vramStart      = 0x8000;
constexpr uint16_t vramEnd        = vramStart + 1024;

// Use the unmapped region at 0xE80x to store the key matrix
constexpr uint16_t keyMatrixStart   = 0xE800;
constexpr uint16_t keyMatrixEnd     = keyMatrixStart + 10;  // 10 rows

// CRTC registers are copied to E8Fx;
constexpr uint16_t crtcStart = 0xE8F0;
constexpr uint16_t crtcEnd   = 0xE900;

bool loadRom(const char* file, uint8_t* pDest, std::streamsize byteSize) {
    std::ifstream input(file, std::ios::binary);
    if (!input.good()) {
        trace("loadRom(): Failed to open '%s'.\n", file);
        return false;
    }

    input.read(reinterpret_cast<char*>(pDest), byteSize);
    if (!input) {
        trace("loadRom(): '%s' too short (expected %u bytes, but got %u bytes).\n", file, byteSize, input.gcount());
        return false;
    }

    input.peek();
    if (!input.eof()) {
        trace("loadRom(): '%s' too long (expected %u bytes).\n", file, byteSize);
        return false;
    }

    input.close();
    trace("ROM Loaded: '%s' (%u Kb)\n", file, byteSize / 1024);
    return true;
}

bool loadRomSet(unsigned index) {
    const RomEntry* pRom = (romSets + index)->roms;

    while (pRom->file != nullptr) {
        std::string path = "roms/";
        std::string file = pRom->file;
        std::string fullPath = path + file;

        if (!loadRom(fullPath.c_str(), memory + pRom->addr, pRom->byteLength)) {
            return false;
        }
        pRom++;
    }

    return true;
}

std::streampos getFileSize(const char* file) {
    std::streampos fsize = 0;
    std::ifstream input(file, std::ios::binary);

    fsize = input.tellg();
    input.seekg(0, std::ios::end);
    fsize = input.tellg() - fsize;
    input.close();

    return fsize;
}

unsigned loadPrg(CDriver driver, const char* file) {
    const auto actualBytes = getFileSize(file);
    if (actualBytes == 0) {
        trace("loadPrg(): File not found: '%s'.\n", file);
        return 0;
    }

    std::ifstream input(file, std::ios::binary);

    // .PRG files begin with a 2B LE header containing load address.
    uint16_t loadAddr;
    input.read(reinterpret_cast<char*>(&loadAddr), 2);
    if (!input) {
        trace("loadPrg(): Expected 2 byte PRG header, but got %u bytes.\n", file, input.gcount());
        return 0;
    }

    if (!input.good()) {
        trace("loadPrg(): Failed to open '%s'.\n", file);
        return 0;
    }

    char* const pDest   = reinterpret_cast<char*>(&memory[loadAddr]);
    const std::streamsize maxSize = 0x8000 - loadAddr;

    input.read(pDest, maxSize);

    input.peek();
    if (!input.eof()) {
        trace("loadPrg(): '%s' out of memory (%u bytes available, but got %u bytes).\n", maxSize, actualBytes);
        return 0;
    }

    input.close();

    // Suspend CPU by setting RDY low
    driver.set_cpu(/* res_b: */ true, /* rdy: */ false);

    // Copy the program to memory at it's load address
    for (uint16_t addr = loadAddr; addr < loadAddr + actualBytes; addr++) {
        driver.pi_write(addr, memory[addr]);
    }

    unsigned size = static_cast<unsigned>(actualBytes) + 0x3FF;

    // Set start of BASIC variables
    driver.pi_write(0xc9, size & 0xFF);
    driver.pi_write(0xca, size >> 8);

    // Set end of current program
    driver.pi_write(0x2a, size & 0xFF);
    driver.pi_write(0x2b, size >> 8);

    // Autorun program by injecting 'RUN:' into the keyboard buffer
    const char keyIn [] = "RUN:\r";
    const auto n = strlen(keyIn);

    for (int i = 0; i < n; i++) {
        driver.pi_write(0x026f + i, keyIn[i]);
    }

    driver.pi_write(0x009e, n);

    // Resume CPU
    driver.set_cpu(/* res_b: */ true, /* rdy: */ true);

    return actualBytes;
}

void display(
    const uint8_t* const pCharRom,
    const size_t charRomByteSize,
    const uint8_t* charRomPage,
    const uint8_t* const pVideoMemory,
    const uint8_t* pCrtcRegs,
    uint8_t keyMatrix[10]
) {
    CDisplay disp(pCharRom, charRomByteSize, charRomPage, pVideoMemory, pCrtcRegs, keyMatrix);

    while (true) {
        disp.update();
    }
}

uint8_t charRom[256 * 8];

void reset(CDriver driver) {
    memset(memory, 0, 0x10000);

    // 4: Basic 4, no-CRTC
    // 6: Basic 4, CRTC, 60 Hz
    bool ok = loadRomSet(6);
    assert(ok);

     // No keys currently pressed
    memset(&memory[keyMatrixStart], 0xFF, keyMatrixEnd - keyMatrixStart);

    // Initialize memory w/expected IO values
    memory[0xE810] = 0xF0;      // Diagonstic sense on bit 7: 0 = TIM, 1 = BASIC
    memory[0xE812] = 0xFF;      // No keys pressed
    memory[0xE813] = 0x80;      // PIA1 CB1
    memory[0xE840] = 0xDF;      // VIA Port B
    memory[0xE84E] = 0x80;

    // Default register values for CRTC
    // (See https://github.com/sjgray/cbm-edit-rom/blob/master/docs/CRTC%20Registers.txt)
    constexpr uint8_t crtc_reg_defaults[16] = {
        0x31, 0x28, 0x29, 0x0f, 0x28, 0x05, 0x19, 0x21,
        0x00, 0x07, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00
    };

    // Initialize CRTC registers w/default values
    memcpy(&memory[crtcStart], crtc_reg_defaults, sizeof(crtc_reg_defaults));

    driver.reset(memory);
}

int main() {
    bool ok = loadRom("roms/characters-2.901447-10.bin", charRom, /* byteSize: */ sizeof(charRom));
    assert(ok);

    std::thread displayThread(display, charRom, sizeof(charRom), &charRomPage, &memory[0x8000], &memory[crtcStart], &memory[0xE800]);

    CDriver driver = CDriver();
    reset(driver);

    while (true) {
        charRomPage = driver.read_gfx() & 1;

        for (uint16_t screenAddr = vramStart; screenAddr < vramEnd; screenAddr++) {
            memory[screenAddr] = driver.pi_read(screenAddr);
        }

        for (uint16_t keyAddr = keyMatrixStart; keyAddr < keyMatrixEnd; keyAddr++) {
            driver.pi_write(keyAddr, memory[keyAddr]);
        }

        for (uint16_t crtc_io_addr = crtcStart; crtc_io_addr < crtcEnd; crtc_io_addr++) {
            const uint8_t r = driver.pi_read(crtc_io_addr);
            if (memory[crtc_io_addr] != r) {
                trace("R%d: %d\n", crtc_io_addr - crtcStart, r);
                memory[crtc_io_addr] = r;
            }
        }

        if (CDisplay::s_funcKey) {
            const unsigned key = 31 - __builtin_clz(CDisplay::s_funcKey);
            
            switch (key + 1) {
                case 1: reset(driver); break;
                case 2: loadPrg(driver, "prgs/a.prg"); break;
                case 3: loadPrg(driver, "prgs/galaga.prg"); break;
                case 4: loadPrg(driver, "prgs/space invaders.prg"); break;
                case 5: loadPrg(driver, "prgs/frobots4.prg"); break;
                case 6: loadPrg(driver, "prgs/crtcx-pet-v1.prg"); break;
            }
            
            CDisplay::s_funcKey &= ~(1 << key);
        }
    }
}
