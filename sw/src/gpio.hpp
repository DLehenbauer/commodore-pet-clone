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

// Constants derived from 'GPIO pads control'
// https://www.scribd.com/doc/101830961/GPIO-Pads-Control2
enum class CGpioSlewRate {
    NotLimited = 0,
    Limited = (1 << 4),
};

// Constants derived from 'GPIO pads control'
// https://www.scribd.com/doc/101830961/GPIO-Pads-Control2
enum class CGpioInputHysteresis {
    Disabled = 0,
    Enabled = (1 << 3),
};

// Constants derived from 'GPIO pads control'
// https://www.scribd.com/doc/101830961/GPIO-Pads-Control2
enum class CGpioDriveStrength {
    Drive_2mA  = 0,
    Drive_4mA  = 1,
    Drive_6mA  = 2,
    Drive_8mA  = 3,
    Drive_10mA = 4,
    Drive_12mA = 5,
    Drive_14mA = 6,
    Drive_16mA = 7,
};

class CGpio {
    public:
        static volatile uint32_t* s_pads;
        static volatile uint32_t* s_gpio;
        static volatile uint32_t* s_gpclk;
        static void init();
        static uint32_t readAll();
        static void writeAll(const uint32_t pinMask, const uint32_t value);
        static void configPad(CGpioSlewRate slew, CGpioInputHysteresis hysteresis, CGpioDriveStrength strength);
        static void clearPinMode(unsigned regOffset, uint32_t gpfClearMask);
        static void setPinMode(unsigned regOffset, uint32_t gpfModeMask);

    protected:
        // Constants derived from BCM2835 ARM Peripherals Spec (pg. 90-91)
        // https://datasheets.raspberrypi.org/bcm2835/bcm2835-peripherals.pdf

        static constexpr unsigned GPFSEL0      =  0; // GPIO Function Select 0 32 R/W 
        static constexpr unsigned GPFSEL1      =  1; // GPIO Function Select 1 32 R/W 
        static constexpr unsigned GPFSEL2      =  2; // GPIO Function Select 2 32 R/W 
        static constexpr unsigned GPFSEL3      =  3; // GPIO Function Select 3 32 R/W 
        static constexpr unsigned GPFSEL4      =  4; // GPIO Function Select 4 32 R/W 
        static constexpr unsigned GPFSEL5      =  5; // GPIO Function Select 5 32 R/W 
        //                        Reserved     =  6;
        static constexpr unsigned GPSET0       =  7; // GPIO Pin Output Set 0 32 W 
        static constexpr unsigned GPSET1       =  8; // GPIO Pin Output Set 1 32 W 
        //                        Reserved     =  9;
        static constexpr unsigned GPCLR0       = 10; // GPIO Pin Output Clear 0 32 W 
        static constexpr unsigned GPCLR1       = 11; // GPIO Pin Output Clear 1 32 W 
        //                        Reserved     = 12;
        static constexpr unsigned GPLEV0       = 13; // GPIO Pin Level 0 32 R 
        static constexpr unsigned GPLEV1       = 14; // GPIO Pin Level 1 32 R 
        //                        Reserved     = 15;
        static constexpr unsigned GPEDS0       = 16; // GPIO Pin Event Detect Status 0 32 R/W 
        static constexpr unsigned GPEDS1       = 17; // GPIO Pin Event Detect Status 1 32 R/W 
        //                        Reserved     = 18;
        static constexpr unsigned GPREN0       = 19; // GPIO Pin Rising Edge Detect Enable 0 32 R/W 
        static constexpr unsigned GPREN1       = 20; // GPIO Pin Rising Edge Detect Enable 1 32 R/W 
        //                        Reserved     = 21;
        static constexpr unsigned GPFEN0       = 22; // GPIO Pin Falling Edge Detect Enable 0 32 R/W 
        static constexpr unsigned GPFEN1       = 23; // GPIO Pin Falling Edge Detect Enable 1 32 R/W
        //                        Reserved     = 24;
        static constexpr unsigned GPHEN0       = 25; // GPIO Pin High Detect Enable 0 32 R/W 
        static constexpr unsigned GPHEN1       = 26; // GPIO Pin High Detect Enable 1 32 R/W 
        //                        Reserved     = 27;
        static constexpr unsigned GPLEN0       = 28; // GPIO Pin Low Detect Enable 0 32 R/W 
        static constexpr unsigned GPLEN1       = 29; // GPIO Pin Low Detect Enable 1 32 R/W 
        //                        Reserved     = 30;
        static constexpr unsigned GPAREN0      = 31; // GPIO Pin Async. Rising Edge Detect 0 32 R/W 
        static constexpr unsigned GPAREN1      = 32; // GPIO Pin Async. Rising Edge Detect 1 32 R/W 
        //                        Reserved     = 33;
        static constexpr unsigned GPAFEN0      = 34; // GPIO Pin Async. Falling Edge Detect 0 32 R/W 
        static constexpr unsigned GPAFEN1      = 35; // GPIO Pin Async. Falling Edge Detect 1 32 R/W 
        //                        Reserved     = 36;
        static constexpr unsigned GPPUD        = 37; // GPIO Pin Pull-up/down Enable 32 R/W 
        static constexpr unsigned GPPUDCLK0    = 38; // GPIO Pin Pull-up/down Enable Clock 0 32 R/W 
        static constexpr unsigned GPPUDCLK1    = 39; // GPIO Pin Pull-up/down Enable Clock 1 32 R/W 
        //                        Reserved     = 40;
        //                        Test         = 41; // 4 R/W
};

// Constants derived from BCM2835 ARM Peripherals Spec (pg. 91-94)
// https://datasheets.raspberrypi.org/bcm2835/bcm2835-peripherals.pdf
enum class CGpioMode {
    Input       = /* 0: */ 0b000,    // GPIO Pin is an input 
    Output      = /* 1: */ 0b001,    // GPIO Pin is an output 
    Alternate5  = /* 2: */ 0b010,    // GPIO Pin takes alternate function 5 
    Alternate4  = /* 3: */ 0b011,    // GPIO Pin takes alternate function 4 
    Alternate0  = /* 4: */ 0b100,    // GPIO Pin takes alternate function 0 
    Alternate1  = /* 5: */ 0b101,    // GPIO Pin takes alternate function 1 
    Alternate2  = /* 6: */ 0b110,    // GPIO Pin takes alternate function 2 
    Alternate3  = /* 7: */ 0b111,    // GPIO Pin takes alternate function 3 
};

// Constants derived from BCM2835 ARM Peripherals Spec (pg. 101)
// https://datasheets.raspberrypi.org/bcm2835/bcm2835-peripherals.pdf
enum class CGpioPullMode {
    Off     = 0b00, // Off – disable pull-up/down 
    Down    = 0b01, // Enable Pull Down control 
    Up      = 0b10, // Enable Pull Up control 
    //      = 0b11, // Reserved
};

template<unsigned TStart, unsigned TCount> class CGpioPins: public CGpio {
    private:
        static constexpr uint32_t getPinMask() {
            assert(TCount > 0);
            assert((TStart + TCount) <= 28);

            return ((1 << (TStart + TCount)) - 1) ^ ((1 << TStart) - 1);
        }

    public:   
        static constexpr uint32_t pinMask           = getPinMask();

    private:
        static constexpr unsigned getGpfRegOffset(const unsigned pin) {
            return pin / 10;
        }

        static constexpr uint32_t getGpfMask(const unsigned selReg, const CGpioMode mode) {
            unsigned min = selReg * 10;
            unsigned max = min + 9;

            // Sanity check that the computed min/max limits map to the same GPFSELx register.
            assert(getGpfRegOffset(min) == getGpfRegOffset(max));

            if (TStart > min) { min = TStart; }

            constexpr unsigned end = TStart + TCount - 1;
            if (end < max) { max = end; }

            // Note that 'min' and 'max' are unsigned, and therefore implicitly >= 0.
            assert(min < 28);
            assert(max < 28);

            const uint32_t mask = static_cast<uint32_t>(mode);
            uint32_t result = 0;

            // Note that 'min > max' when the pin range does not intersect the current GPFSELx register.
            for (unsigned p = min; p <= max; p++) {
                result |= mask << ((p % 10) * 3);
            }

            return result;
        }

    public:
        static constexpr uint32_t gpfRegStart       = getGpfRegOffset(TStart);
        static constexpr uint32_t gpfRegEnd         = getGpfRegOffset(TStart + TCount - 1);

        static constexpr uint32_t gpfClearMask[]    = {
            ~getGpfMask(/* GPFSELx: */ 0, /* mode: */ static_cast<CGpioMode>(7)),
            ~getGpfMask(/* GPFSELx: */ 1, /* mode: */ static_cast<CGpioMode>(7)),
            ~getGpfMask(/* GPFSELx: */ 2, /* mode: */ static_cast<CGpioMode>(7)),
        };

        static constexpr uint32_t gpfOutputMask[]    = {
            getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Output),
            getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Output),
            getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Output),
        };

        static constexpr uint32_t gpfModeMask[8][3]  = {
            // Input       = /* 0: */ 0b000,    // GPIO Pin is an input 
            {
                getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Input),
                getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Input),
                getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Input),
            },

            // Output      = /* 1: */ 0b001,    // GPIO Pin is an output 
            {
                getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Output),
                getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Output),
                getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Output),
            },

            // Alternate5  = /* 2: */ 0b010,    // GPIO Pin takes alternate function 5 
            {
                getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Alternate5),
                getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Alternate5),
                getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Alternate5),
            },

            // Alternate4  = /* 3: */ 0b011,    // GPIO Pin takes alternate function 4 
            {
                getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Alternate4),
                getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Alternate4),
                getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Alternate4),
            },

            // Alternate0  = /* 4: */ 0b100,    // GPIO Pin takes alternate function 0
            {
                getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Alternate0),
                getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Alternate0),
                getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Alternate0),
            },

            // Alternate1  = /* 5: */ 0b101,    // GPIO Pin takes alternate function 1 
            {
                getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Alternate1),
                getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Alternate1),
                getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Alternate1),
            },

            // Alternate2  = /* 6: */ 0b110,    // GPIO Pin takes alternate function 2
            {
                getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Alternate2),
                getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Alternate2),
                getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Alternate2),
            },

            // Alternate3  = /* 7: */ 0b111,    // GPIO Pin takes alternate function 3 
            {
                getGpfMask(/* GPFSELx: */ 0, /* mode: */ CGpioMode::Alternate3),
                getGpfMask(/* GPFSELx: */ 1, /* mode: */ CGpioMode::Alternate3),
                getGpfMask(/* GPFSELx: */ 2, /* mode: */ CGpioMode::Alternate3),
            }
        };

        CGpioPins(CGpioMode mode = CGpioMode::Input, CGpioPullMode pullMode = CGpioPullMode::Off) {
            CGpio::init();
            
            setPinMode(mode);
            setPullMode(pullMode);
        }

        void inputMode() const {
            for (unsigned regOffset = gpfRegStart; regOffset <= gpfRegEnd; regOffset++) {
                CGpio::clearPinMode(regOffset, gpfClearMask[regOffset]);
            }
        }

        void outputMode() const {
            for (unsigned regOffset = gpfRegStart; regOffset <= gpfRegEnd; regOffset++) {
                CGpio::setPinMode(regOffset, gpfOutputMask[regOffset]);
            }
        }

        void setPinMode(const CGpioMode mode) const {
            inputMode();

            const uint32_t* modeMask = gpfModeMask[static_cast<unsigned>(mode)];

            for (unsigned regOffset = gpfRegStart; regOffset <= gpfRegEnd; regOffset++) {
                CGpio::setPinMode(regOffset, modeMask[regOffset]);
            }
        }

        uint32_t read() const {
            constexpr unsigned lsh = 32 - TStart - TCount;
            constexpr unsigned rsh = lsh + TStart;

            return (readAll() << lsh) >> rsh;
        }

        void write(const uint32_t value) const {
            writeAll(pinMask, value << TStart);
        }

        void setPullMode(const CGpioPullMode mode) const {
            // See BCM2835 ARM Peripherals Spec (pg. 101)
            // https://datasheets.raspberrypi.org/bcm2835/bcm2835-peripherals.pdf

            *(CGpio::s_gpio + GPPUD) = static_cast<uint32_t>(mode);

            // Wait 150 cycles – this provides the required set-up time for the control signal 
            usleep(1);

            *(CGpio::s_gpio + GPPUDCLK0) = pinMask;
            
            // Wait 150 cycles – this provides the required hold time for the control signal
            usleep(1);
            
            *(CGpio::s_gpio + GPPUD) = 0;
            *(CGpio::s_gpio + GPPUDCLK0) = 0;
        }

        static constexpr unsigned pinStart = TStart;
        static constexpr unsigned pinCount = TCount;
};

// Constants derived from BCM2835 ARM Peripherals Spec (pg. 107)
// https://datasheets.raspberrypi.org/bcm2835/bcm2835-peripherals.pdf

enum class CGpClockSource {     //  RPi 0-3     RPi 4
    GND        = 0,             //    0 Hz
    Oscillator = 1,             // 19.2 MHz      54 MHz
    TestDebug0 = 2,             //    0 Hz
    TestDebug1 = 3,             //    0 Hz
    PLLA       = 4,             //    0 Hz
    PLLC       = 5,             // 1000 MHz*   1000 MHz*    * Changes w/overclocking
    PLLD       = 6,             //  500 MHz     750 MHz
    HDMI       = 7,             //  216 MHz
    // GND     = 8-15           //    0 Hz
};

// Constants derived from BCM2835 ARM Peripherals Spec (pg. 107)
// https://datasheets.raspberrypi.org/bcm2835/bcm2835-peripherals.pdf
enum class CGpClockMASHStage {
    Stage0 = 0 << 9, // Integer division
    Stage1 = 1 << 9, // 1-stage MASH (equivalent to non-MASH dividers) 
    Stage2 = 2 << 9, // 2-stage MASH
    Stage3 = 3 << 9, // 3-stage MASH 
};

enum class CGpClockId {
    GP0 = 28,       // GPIO 4 (Alt0)
    GP1 = 30,       // GPIO 5 ()
    GP2 = 32,       // GPIO 6 ()
};

class CGpClock {
    private:
        // Constants derived from BCM2835 ARM Peripherals Spec (pg. 107)
        // https://datasheets.raspberrypi.org/bcm2835/bcm2835-peripherals.pdf
        
        static constexpr uint32_t GPCLK_PASSWD      = 0x5A << 24;
        static constexpr uint32_t GPCLK_CTL_BUSY    = 1 << 7;
        static constexpr uint32_t GPCLK_CTL_KILL    = 1 << 5;
        static constexpr uint32_t GPCLK_CTL_ENAB    = 1 << 4;

    public:
        static void stop(CGpClockId clock) {
            volatile uint32_t* const clkCtl = CGpio::s_gpclk + (static_cast<unsigned>(clock));

            // Request the clock to stop.
            *clkCtl = GPCLK_PASSWD | GPCLK_CTL_KILL;

            // The output clock will not stop immediately because the cycle must be allowed to
            // complete to avoid glitches. The BUSY flag will go low when the final cycle is completed.
            while (*clkCtl & GPCLK_CTL_BUSY);
        }

        static void start(CGpClockId clock, CGpClockSource source, unsigned divI, unsigned divF, CGpClockMASHStage MASH) {
            // Per spec, modifying 's_gpclk' without first waiting for the clock to stop
            // may result in lock-ups and glitches. (pg. 107)
            // https://datasheets.raspberrypi.org/bcm2835/bcm2835-peripherals.pdf
            stop(clock);

            volatile uint32_t* const clkCtl = CGpio::s_gpclk + (static_cast<unsigned>(clock));
            volatile uint32_t* const clkDiv = clkCtl + 1;

            *clkDiv = (GPCLK_PASSWD | (divI << 12) | divF);
            *clkCtl = (GPCLK_PASSWD | static_cast<uint32_t>(MASH) | static_cast<uint32_t>(source));
            *clkCtl |= (GPCLK_PASSWD | GPCLK_CTL_ENAB);
        }
};
