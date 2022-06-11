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

#include <bcm_host.h>
#include "gpio.hpp"
#include "trace.hpp"

volatile uint32_t* CGpio::s_gpio = nullptr;
volatile uint32_t* CGpio::s_pads = nullptr;
volatile uint32_t* CGpio::s_gpclk = nullptr;

void CGpio::init() {
    if (CGpio::s_gpio != nullptr) {
        return;
    }

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        fprintf(stderr, "Unable to open /dev/mem. Run as root using sudo?\n");
        exit(-1);
    }

    void *gpio_map = mmap(
        nullptr,
        bcm_host_get_peripheral_size(),
        PROT_READ | PROT_WRITE,
        MAP_SHARED | MAP_LOCKED,
        fd,
        bcm_host_get_peripheral_address()
    );

    close(fd);

    if (gpio_map == MAP_FAILED) {
        printf("mmap failed, errno = %d\n", errno);
        exit(-1);
    }

    CGpio::s_gpio  = ((volatile uint32_t *) gpio_map) + (0x00200000 / 4);
    CGpio::s_pads  = ((volatile uint32_t *) gpio_map) + (0x00100000 / 4);
    CGpio::s_gpclk = ((volatile uint32_t *) gpio_map) + (0x00101000 / 4);
}

void CGpio::configPad(CGpioSlewRate slew, CGpioInputHysteresis hysteresis, CGpioDriveStrength strength) {
    // See 'GPIO pads control'
    // https://www.scribd.com/doc/101830961/GPIO-Pads-Control2
    *(CGpio::s_pads + 11) = 0x5a000000
        | static_cast<uint32_t>(slew)
        | static_cast<uint32_t>(hysteresis)
        | static_cast<uint32_t>(strength);
}

uint32_t CGpio::readAll() {
    return *(CGpio::s_gpio + GPLEV0);
}

void CGpio::writeAll(const uint32_t pinMask, const uint32_t value) {
    assert(pinMask <= 0xFFFFFFF);
    assert((value & pinMask) == value);

    const uint32_t toClear = (~value) & pinMask;
    if (toClear != 0) {
        *(CGpio::s_gpio + GPCLR0) = toClear;
    }

    const uint32_t toSet = value & pinMask;
    if (toSet != 0) {
        *(CGpio::s_gpio + GPSET0) = toSet;
    }
}

void CGpio::clearPinMode(unsigned regOffset, uint32_t gpfClearMask) {
    *(CGpio::s_gpio + regOffset) &= gpfClearMask;
}

void CGpio::setPinMode(unsigned regOffset, uint32_t gpfModeMask) {
    *(CGpio::s_gpio + regOffset) |= gpfModeMask;
}
