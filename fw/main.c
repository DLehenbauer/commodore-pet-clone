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

// #define TEST

#include "pch.h"
#include "driver.h"
#include "dvi/dvi.h"
#include "global.h"
#include "sd/sd.h"
#include "fpga/fpga.h"

#ifdef TEST
#include "test.h"
#else
#include "pet.h"
#endif

#include "usb/usb.h"

void init() {
    fpga_init();
    fpga_config();
    printf("FPGA initialized.\n");
    driver_init();
    printf("Driver initialized.\n");
    init_sd();
    printf("SD initialized.\n");
    usb_init();
    printf("USB initialized.\n");
    video_init();
    printf("Video initialized.\n");
}

int main() {
    init();

#ifdef TEST
    test_ram();
    // test_display();
#else
    pet_reset();
    printf("PET reset.\n");
    pet_main();
#endif

    __builtin_unreachable();
}
