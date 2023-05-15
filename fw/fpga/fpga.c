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

#include "fpga.h"
#include "hw.h"

static const uint8_t __in_flash(".fpga_bitstream") bitstream[] = {
    #include "./bitstream.h"
};

void measure_freqs(uint fpga_div) {
    uint32_t f_pll_sys = frequency_count_khz(CLOCKS_FC0_SRC_VALUE_PLL_SYS_CLKSRC_PRIMARY);
    uint32_t f_pll_usb = frequency_count_khz(CLOCKS_FC0_SRC_VALUE_PLL_USB_CLKSRC_PRIMARY);
    uint32_t f_rosc = frequency_count_khz(CLOCKS_FC0_SRC_VALUE_ROSC_CLKSRC);
    uint32_t f_clk_sys = frequency_count_khz(CLOCKS_FC0_SRC_VALUE_CLK_SYS);
    uint32_t f_clk_peri = frequency_count_khz(CLOCKS_FC0_SRC_VALUE_CLK_PERI);
    uint32_t f_clk_usb = frequency_count_khz(CLOCKS_FC0_SRC_VALUE_CLK_USB);
    uint32_t f_clk_adc = frequency_count_khz(CLOCKS_FC0_SRC_VALUE_CLK_ADC);
    uint32_t f_clk_rtc = frequency_count_khz(CLOCKS_FC0_SRC_VALUE_CLK_RTC);

    printf("    pll_sys  = %d kHz\n", f_pll_sys);
    printf("    pll_usb  = %d kHz\n", f_pll_usb);
    printf("    rosc     = %d kHz\n", f_rosc);
    printf("    clk_sys  = %d kHz\n", f_clk_sys);
    printf("    clk_peri = %d kHz\n", f_clk_peri);
    printf("    clk_usb  = %d kHz\n", f_clk_usb);
    printf("    clk_adc  = %d kHz\n", f_clk_adc);
    printf("    clk_rtc  = %d kHz\n", f_clk_rtc);
    printf("    clk_fpga = %d kHz\n", f_clk_sys / fpga_div);
}

void fpga_init() {
    gpio_init(FPGA_CRESET_GP);

    // Setup 270 MHz system clock
	vreg_set_voltage(VREG_VOLTAGE_1_20);
	sleep_ms(10);
 	set_sys_clock_khz(270000, true);

    // FPGA CLK: 270 MHz / 6 = 45 MHz
    const uint16_t fpga_div = 6;

    const uint slice = pwm_gpio_to_slice_num(FPGA_CLK_GP);
    const uint channel = pwm_gpio_to_channel(FPGA_CLK_GP);
    pwm_config config = pwm_get_default_config();
    pwm_config_set_wrap(&config, fpga_div - 1);
    pwm_init(slice, &config, /* start: */ true);
    pwm_set_chan_level(slice, channel, 2);
    gpio_set_drive_strength(FPGA_CLK_GP, GPIO_DRIVE_STRENGTH_2MA);
    gpio_set_function(FPGA_CLK_GP, GPIO_FUNC_PWM);

    // Setting 'sys_clk' causes 'peri_clk' to revert to 48 MHz.  (Re)initialize UART.
    //
    // See: https://github.com/Bodmer/TFT_eSPI/discussions/2432
    // See: https://github.com/raspberrypi/pico-examples/blob/master/clocks/hello_48MHz/hello_48MHz.c
    stdio_init_all();
    printf("\e[2J");
    printf("Clocks initialized:\n");
    measure_freqs(fpga_div);
}

bool fpga_config() {
    gpio_init(FPGA_CRESET_GP);

    if (gpio_get(FPGA_CRESET_GP)) {
        printf("FPGA config skipped: Programmer attached.\n");
        return false;
    }

    // Drive CRESET_N low to initiate FPGA configuration.
    //
    // TODO: Alternatively, leave CRESET_N as an input and let pulldown drive low.
    gpio_init(FPGA_CRESET_GP);
    gpio_set_dir(FPGA_CRESET_GP, GPIO_OUT);

    gpio_put(FPGA_CRESET_GP, 1);
    sleep_ms(1);  // t_CRESET_N = 320 ns
    gpio_put(FPGA_CRESET_GP, 0);

    sleep_ms(1);  // t_CRESET_N = 320 ns

    // Configure CS_N as GPIO_OUT rather than GPIO_FUNC_SPI so we can control via software.
    gpio_init(SPI0_CSN_GP);
    gpio_put(SPI0_CSN_GP, 1);
    gpio_set_dir(SPI0_CSN_GP, GPIO_OUT);

    spi_init(spi0, 6 * 1000 * 1000);
    gpio_set_function(SPI0_SCK_GP, GPIO_FUNC_SPI);
    gpio_set_function(SPI0_TX_GP, GPIO_FUNC_SPI);
    gpio_set_function(SPI0_RX_GP, GPIO_FUNC_SPI);

    // Efinix requires SPI Mode 3 for configuration.
    spi_set_format(spi0, 8, SPI_CPOL_1, SPI_CPHA_1, SPI_MSB_FIRST);

    // Changes in clock polarity do not seem to take effect until the next write.  Send
    // a single byte while CS_N is deasserted to transition SCK to high.
    uint8_t buffer[125] = { 0 };
    spi_write_blocking(spi0, buffer, 1);
    sleep_ms(1);  // t_CRESET_N = 320 ns

    // The Efinix FPGA samples CS_N on the positive edge of CRESET_N to select passive
    // vs. active SPI configuration.  (0 = Passive, 1 = Active)
    gpio_put(SPI0_CSN_GP, 0);

    sleep_ms(1);  // t_CRESET_N = 320 ns
    gpio_put(FPGA_CRESET_GP, 1);

    printf("FPGA: Sending %d bytes\n", sizeof(bitstream));
    spi_write_blocking(spi0, bitstream, sizeof(bitstream));

    // Efinix example clocks out 1000 zero bits to generate extra clock cycles.
    spi_write_blocking(spi0, buffer, sizeof(buffer));

    sleep_ms(1);  // t_CRESET_N = 320 ns

    printf("FPGA: DONE\n");
    gpio_put(SPI0_CSN_GP, 1);

    return true;
}
