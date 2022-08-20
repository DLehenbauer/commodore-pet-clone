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

        // $E81x: PIA 1
        // $E82x: PIA 2
        // $E84x: VIA
        // $E88x: CRTC
        static bool is_io_aperture(const uint16_t addr) {
            return 0xE800 <= addr && addr <= 0xE8FF;
        }

        static bool is_read_only(const uint16_t addr) {
            return addr >= 0x9000 && !is_io_aperture(addr);
        }

        void read_bus_unchecked() {
            uint32_t bits = CGpio::readAll();

            rw_b = (bits & (1 << rwbPin.pinStart)) != 0;
            if (rw_b) {
                dataPins.outputMode();
            }

            const uint16_t a15    = (bits >> a15Pin.pinStart) << 15;
            const uint16_t a0to14 = (bits >> a0to14Pins.pinStart) & 0x7FFF;
            addr = a15 | a0to14;
            data = bits >> dataPins.pinStart;
        }

        bool vet_core(
            const uint16_t expected_addr,
            const uint8_t expected_data,
            const bool expected_rw_b,
            bool compareData,
            bool show
        ) const {
            const bool eq_addr = addr == expected_addr;
            const bool eq_data = (!compareData) || (data == expected_data);
            const bool eq_rw_b = rw_b == expected_rw_b;

            const bool eq = eq_rw_b && eq_addr && eq_data;
            const bool legal = rw_b || (addr < 0x9000 || (0xE800 < addr && addr < 0xf000));
            const bool result = eq && legal;

            if (!result) {
                trace("IO ERROR:\n");
                show = true;
            } else if (show) {
                trace("IO OK:\n");
            }

            if (show) {
                trace("  [%s] rw_b: %s (%d) %s %s (%d)\n",
                    eq_rw_b
                        ? legal
                            ? " OK "
                            : "ILLG"
                        : "FAIL",
                    rw_b ? "RD" : "WR",
                    rw_b,
                    eq_rw_b ? "==" : "!=",
                    expected_rw_b ? "RD" : "WR",
                    expected_rw_b);
                trace("  [%s] addr: %04x %s %04x\n", eq_addr ? " OK " : "FAIL", addr, eq_addr ? "==" : "!=", expected_addr);
                if (compareData) {
                    trace("  [%s] data: %02x %s %02x\n", eq_data ? " OK " : "FAIL", data, eq_data ? "==" : "!=", expected_data);
                }
            }

            return result;
        }

        void trace_bus() {
            if (rw_b) {
                trace("R: (%04x) -> %02x\n", addr, data);
            } else {
                trace("W: (%04x) <- %02x\n", addr, data);
            }
        }

        void sniff_bus() {
            pendingbPin.write(1);
            rwbPin.inputMode();
            a15Pin.inputMode();
            a0to14Pins.inputMode();
            dataPins.inputMode();

            uint32_t bits = CGpio::readAll();
            const bool rw_b       = (bits & (1 << rwbPin.pinStart)) != 0;
            const uint16_t a15    = (bits >> a15Pin.pinStart) << 15;
            const uint16_t a0to14 = (bits >> a0to14Pins.pinStart) & 0x7FFF;
            const uint16_t addr = a15 | a0to14;
            const uint16_t data = bits >> dataPins.pinStart;

            if (rw_b) {
                trace("R: (%04x) -> %02x\n", addr, data);
            } else {
                trace("W: (%04x) <- %02x\n", addr, data);
            }
        }

        void vet(bool compareData) {
            bool ok = false;
            for (int c = -1; !ok && c < 3; c++) {
                uint16_t expected_addr = addr;
                uint8_t expected_data = data;
                bool expected_rw_b = rw_b;
                read_bus_unchecked();

                const bool first_attempt = c == -1;
                ok = vet_core(expected_addr, expected_data, expected_rw_b, compareData, /* show: */ !first_attempt);
                if (ok && first_attempt) {
                    return;
                }

                usleep(100);
            }

            assert(false);
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
            const uint8_t actual = dataPins.read();
            if (actual != data) {
                trace("READ ERROR:");
                trace("  [FAIL] %04x: %02x != %02x\n", addr, actual, data);
                assert(false);
            }

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

            const uint8_t actual = pi_read(addr);
            if (actual != data) {
                trace("WRITE ERROR:");
                trace("  [FAIL] %04x: %02x != %02x\n", addr, actual, data);
                assert(false);
            }
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
                    trace("Skipping %s: %4x-%4x\n", next_skip->desc, addr, skipEnd);
                    addr = skipEnd;
                    next_skip++;
                } else {
                    f(addr);
                }
            }
        }

        void ram_test() {
            constexpr uint8_t checkers[4] = {
                0b11111111,
                0b11110000,
                0b11001100,
                0b10101010,
            };

            for (unsigned i = 0; i < 4; i++) {
                const uint8_t pattern[2] = { checkers[i], static_cast<uint8_t>(~checkers[i]) };

                trace("RAM test: %02x %02x\n", pattern[0], pattern[0]);
                foreach_addr([this, pattern](uint16_t addr) {
                    pi_write(addr, pattern[0]);
                });

                trace("RAM test: %02x %02x\n", pattern[0], pattern[1]);
                foreach_addr([this, pattern](uint16_t addr) {
                    const uint16_t index = static_cast<uint16_t>(addr & 1);
                    pi_write(addr, pattern[index]);
                });

                trace("RAM test: %02x %02x\n", pattern[1], pattern[0]);
                foreach_addr([this, pattern](const uint16_t addr) {
                    const uint16_t index = static_cast<uint16_t>(~addr & 1);
                    pi_write(addr, pattern[index]);
                });

                if (pattern[1] != 0) {
                    trace("RAM test: %02x %02x\n", pattern[1], pattern[1]);
                    foreach_addr([this, pattern](uint16_t addr) {
                        pi_write(addr, pattern[1]);
                    });
                }
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
                const uint8_t data = memory[addr];
                const uint8_t actual = pi_read(addr);
                if (actual != data) {
                    trace("VERIFY ERROR:");
                    trace("  [FAIL] %04x: %02x != %02x\n", addr, actual, data);
                    assert(false);
                }
            });

            // Reset will re-initialize PHI2 at 1 MHz 
            set_cpu(/* res_b: */ false, /* rdy: */ false);
            set_cpu(/* res_b: */ true, /* rdy: */ true);
        }

        bool read_gfx() {
            return pi_read(0xE80E) & 1;
        }
};
