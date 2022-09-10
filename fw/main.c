#include <stdio.h>
#include "pico/stdlib.h"

int main() {
    stdio_init_all();

    while (true) {
        printf("UART via Picoprobe.\n");
        sleep_ms(1000);
    }
    
    return 0;
}
