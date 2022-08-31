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

#include "gpio.hpp"
#include "trace.hpp"

class CDriver {
    private:
        static const CGpioPins</* start: */ 0, /* count: */ 1> rwbPin;
        static const CGpioPins</* start: */ 1, /* count: */ 1> a15Pin;
        static const CGpioPins</* start: */ 2, /* count: */ 1> pendingbPin;
        static const CGpioPins</* start: */ 3, /* count: */ 1> donebPin;
        static const CGpioPins</* start: */ 4, /* count: */ 1> clkPin;
        static const CGpioPins</* start: */ 5, /* count: */ 15> a0to14Pins;
        static const CGpioPins</* start: */ 20, /* count: */ 8> dataPins;

        // rwb  = gpio0
        // a15  = gpio1
        // pend = gpio2
        // done = gpio3
        // clk  = gpio4
        // a0   = gpio5
        // a1   = gpio6
        // a2   = gpio7
        // a3   = gpio8
        // a4   = gpio9  (MISO)
        // a5   = gpio10 (MOSI)
        // a6   = gpio11 (SCLK)
        // a7   = gpio12
        // a8   = gpio13
        // a9   = gpio14 (TXD)
        // a10  = gpio15 (RXD)
        // a11  = gpio16
        // a12  = gpio17
        // a13  = gpio18
        // a14  = gpio19
        // d0   = gpio20
        // d1   = gpio21
        // d2   = gpio22
        // d3   = gpio23
        // d4   = gpio24
        // d5   = gpio25
        // d6   = gpio26
        // d7   = gpio27

        uint16_t addr;
        uint8_t data;
        bool rw_b;

    public:
        CDriver() {
            CGpio::configPad(CGpioSlewRate::Limited, CGpioInputHysteresis::Enabled, CGpioDriveStrength::Drive_8mA);

            pendingbPin.write(1);
            pendingbPin.setPinMode(CGpioMode::Output);
            
            donebPin.setPinMode(CGpioMode::Input);

            clkPin.write(1);
            clkPin.setPinMode(CGpioMode::Output);

            rwbPin.write(1);
            rwbPin.setPinMode(CGpioMode::Output);
            
            a15Pin.setPinMode(CGpioMode::Output);
            a0to14Pins.setPinMode(CGpioMode::Output);
            
            dataPins.setPinMode(CGpioMode::Input);
        }

        // Helper invoked by pi_read(), pi_write(), and ram_test() when ensuring that reads produce
        // an expected value.
        static void assert_equal(const char* kind, uint16_t addr, uint8_t actual, uint8_t expected) {
            if (actual != expected) {
                trace("%s ERROR:\n", kind);
                trace("  [FAIL] $%04x: Expected $%02x, but got $%02x\n", addr, expected, actual);
                assert(false);
            }
        }

        static constexpr uint32_t get_addr_bits(const uint16_t addr) {
            return (static_cast<uint32_t>(addr >> 15) << a15Pin.pinStart)
                | (static_cast<uint32_t>(addr & 0x7fff) << a0to14Pins.pinStart);
        }

        uint8_t pi_read(uint16_t addr) {
            uint32_t bits = get_addr_bits(addr);
            bits |= (1 << rwbPin.pinStart);
            dataPins.inputMode();

            constexpr uint32_t mask = rwbPin.pinMask | a15Pin.pinMask | a0to14Pins.pinMask;

            CGpio::writeAll(mask, bits);
            pendingbPin.write(0);

            while (donebPin.read());

            const uint8_t data = dataPins.read();

            // While holding pending high, perform a second read as a sanity check to help detect glitches.
            const uint8_t actual = dataPins.read();
            assert_equal("READ", addr, actual, /* expected: */ data);

            pendingbPin.write(1);

            return data;
        }

        void pi_write(uint16_t addr, uint8_t data) {
            uint32_t bits = get_addr_bits(addr);
            bits |= (static_cast<uint32_t>(data) << dataPins.pinStart);

            constexpr uint32_t mask = rwbPin.pinMask | a15Pin.pinMask | a0to14Pins.pinMask | dataPins.pinMask;

            CGpio::writeAll(mask, bits);
            dataPins.outputMode();
            pendingbPin.write(0);

            while (donebPin.read());

            pendingbPin.write(1);

            // Immediately after completing the write, request a read of the same address as a sanity
            // check to help detect glitches.  Note that this could fail if the 6502 were enabled and
            // concurrently writing to the same address.  However, our current usage only writes when
            // the 6502 is suspended or to shadowed address ranges not reachable by the CPU.
            const uint8_t actual = pi_read(addr);
            assert_equal("WRITE", addr, actual, /* expected: */ data);
        }

        void set_clock(double mhz) {
            const unsigned int divI = static_cast<unsigned int>(500.0 / 16.0 / mhz);

            CGpClock::start(
                CGpClockId::GP0,
                CGpClockSource::PLLD,
                divI,
                /* divF: */ 0,
                CGpClockMASHStage::Stage0);

            printf("Clock speed %.1lf MHz\n", mhz);
        }

        void stop_clock() {
            CGpClock::stop(CGpClockId::GP0);
            clkPin.write(0);
            clkPin.setPinMode(CGpioMode::Output);
        }

        void set_cpu(bool res_b, bool rdy) {
            clkPin.setPinMode(CGpioMode::Alternate0);
            set_clock(/* MHz: */ 1.0);

            pi_write(0xE80F,
                (res_b ? (1 << 0) : 0)
                | (rdy ? (1 << 1) : 0));
            
            usleep(1);
        }

        void foreach_addr(const std::function<void(uint16_t)> &f) {
            typedef struct {
                uint16_t    start;
                uint16_t    length;
                const char* desc;
            } skip_entry;

            // Most RPi addresses update RAM, even if mapped to IO for the CPU.
            constexpr skip_entry skips[] = {
                { 0xE80E, 0x00, "Gfx Register" },
                { 0xE80F, 0x00, "CPU Control" },
                { 0xE810, 0x00, "PIA port A" },
                { 0xE880, 0x7F, "CRTC" },
                { 0, 0, "" }
            };
            
            const skip_entry* next_skip = &skips[0];
            
            for (unsigned addr = 0x0000; addr < 0x10000; addr++) {
                if (addr == next_skip->start) {
                    const unsigned skipEnd = addr + next_skip->length;
                    trace("  Skipping %s: $%4x-%4x\n", next_skip->desc, addr, skipEnd);
                    addr = skipEnd;
                    next_skip++;
                } else {
                    f(addr);
                }
            }
        }

        void write_test_pattern(const uint8_t evenPattern, const uint8_t oddPattern) {
            const uint8_t patterns[2] = { evenPattern, oddPattern };

            trace("Writing: %02x %02x\n", patterns[0], patterns[1]);
            foreach_addr([this, patterns](uint16_t addr) {
                const uint16_t index = addr & 1;
                pi_write(addr, patterns[index]);
            });

            trace("Reading: %02x %02x\n", patterns[0], patterns[1]);
            foreach_addr([this, patterns](uint16_t addr) {
                const uint16_t index = addr & 1;
                const uint8_t expected = patterns[index];
                const uint8_t actual = pi_read(addr);
                assert_equal("VERIFY", addr, actual, expected);
            });
        }

        void ram_test() {
            constexpr uint8_t checkers[4] = {
                0b11111111,
                0b11110000,
                0b11001100,
                0b10101010,
            };

            for (unsigned i = 0; i < sizeof(checkers); i++) {
                const uint8_t pattern0 =  checkers[i];
                const uint8_t pattern1 = ~pattern0;

                write_test_pattern(pattern0, pattern0);
                write_test_pattern(pattern0, pattern1);
                write_test_pattern(pattern1, pattern0);
                write_test_pattern(pattern1, pattern1);
            }
        }

        void reset(uint8_t memory[]) {
            set_cpu(/* res_b: */ false, /* rdy: */ false);
            set_cpu(/* res_b: */ true, /* rdy: */ false);

            // Increase PHI2 while initializing/testing RAM
            set_clock(/* MHz: */ 1.0);

            ram_test();

            // Init RAM with contents of 'memory'
            foreach_addr([this, memory](uint16_t addr) {
                pi_write(addr, memory[addr]);
            });

            // Verify RAM contents match 'memory'
            foreach_addr([this, memory](uint16_t addr) {
                const uint8_t expected = memory[addr];
                const uint8_t actual = pi_read(addr);
                assert_equal("VERIFY", addr, actual, expected);
            });

            // Reset will re-initialize PHI2 at 1 MHz 
            set_cpu(/* res_b: */ false, /* rdy: */ false);
            set_cpu(/* res_b: */ true, /* rdy: */ true);
        }

        bool read_gfx() {
            return pi_read(0xE80E) & 1;
        }
};
