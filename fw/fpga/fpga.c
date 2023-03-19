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
#include "sd/sd.h"
#include "./hw.h"
#include "f_util.h"
#include "ff.h"
#include "diskio.h"

static const uint8_t __in_flash() bitstream[] = {
    #include "./bitstream.h"
};

void init_fpga() {
    // TODO: Read CRESET_N to see if an attached programming is driving CRESET_N=1
    //       to avoid potential contention.
    
    // Drive CRESET_N low to initiate FPGA configuration.
    //
    // TODO: Alternatively, leave CRESET_N as an input and let pulldown drive low.
    gpio_init(FPGA_CRESET_GP);
    gpio_set_dir(FPGA_CRESET_GP, GPIO_OUT);

    gpio_put(FPGA_CRESET_GP, 1);
    sleep_ms(1);  // t_CRESET_N = 320 ns
    gpio_put(FPGA_CRESET_GP, 0);

    // Setup 270 MHz system clock
	vreg_set_voltage(VREG_VOLTAGE_1_20);
	sleep_ms(10);
 	set_sys_clock_khz(270000, true);

    // FPGA CLK: 270 MHz / 6 = 45 MHz
    const uint slice = pwm_gpio_to_slice_num(FPGA_CLK_GP);
    const uint channel = pwm_gpio_to_channel(FPGA_CLK_GP);
    pwm_config config = pwm_get_default_config();
    pwm_config_set_wrap(&config, 5);
    pwm_init(slice, &config, /* start: */ true);
    pwm_set_chan_level(slice, channel, 2);
    gpio_set_function(FPGA_CLK_GP, GPIO_FUNC_PWM);

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
}
