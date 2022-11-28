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

#include "pch.h"
#include "driver.h"
#include "dvi/dvi.h"
#include "global.h"
#include "pet.h"
// #include "test.h"
#include "usb/usb.h"

void init() {
    stdio_init_all();
    driver_init();
    usb_init();
    video_init();
}

int main() {
    init();

    pet_reset();
    pet_main();

    // test_init();
    // test_display();

    __builtin_unreachable();
}
