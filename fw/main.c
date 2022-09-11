#include <stdio.h>
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/spi.h"

int main() {
    stdio_init_all();

    spi_init(spi0, /* 50 MHz */ 50 * 1000 * 1000);
    spi_set_slave(spi0, /* slave: */ true);
    
    gpio_set_function(2, GPIO_FUNC_SPI);
    gpio_set_function(3, GPIO_FUNC_SPI);
    gpio_set_function(4, GPIO_FUNC_SPI);
    gpio_set_function(5, GPIO_FUNC_SPI);

    uint8_t bytes [] = { 0xd4 };

    while (true) {
        spi_read_blocking(spi0, /* tx: */ 0, bytes, sizeof(bytes));
        sleep_ms(100);
    }

    return 0;
}
