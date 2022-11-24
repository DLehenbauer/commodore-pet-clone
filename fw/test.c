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

#include "test.h"
#include "driver.h"

void test_init() {
    set_cpu(/* reset: */ true, /* run: */ false);
    sleep_ms(1);

    set_cpu(/* reset: */ false, /* run: */ false);
    sleep_ms(1);
}

void test_display() {

}
