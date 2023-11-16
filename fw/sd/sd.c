#include "sd.h"
#include "f_util.h"
#include "ff.h"
#include "rtc.h"
#include "diskio.h"
#include "hw_config.h"
#include "../hw.h"

// Hardware Configuration of SPI "objects"
// Note: multiple SD cards can be driven by one SPI if they use different slave
// selects.
static spi_t spis[] = {  // One for each SPI.
    {
        .hw_inst    = SD_SPI_INSTANCE,
        .miso_gpio  = SD_DAT_GP,
        .mosi_gpio  = SD_CMD_GP,
        .sck_gpio   = SD_CLK_GP,
        .set_drive_strength = true,
        .mosi_gpio_drive_strength = GPIO_DRIVE_STRENGTH_2MA,
        .sck_gpio_drive_strength = GPIO_DRIVE_STRENGTH_2MA,

         .baud_rate = 1000 * 1000,
        //.baud_rate = 12500 * 1000,  // The limitation here is SPI slew rate.
        //.baud_rate = 25 * 1000 * 1000, // Actual frequency: 20833333. Has
        // worked for me with SanDisk.
    }
};

// Hardware Configuration of the SD Card "objects"
static sd_card_t sd_cards[] = {  // One for each SD card
    {
        .pcName = "0:",           // Name used to mount device
        .spi = &spis[0],          // Pointer to the SPI driving this card
        .ss_gpio = SD_CSN_GP,     // The SPI slave select GPIO for this SD card
        .set_drive_strength = true,
        .ss_gpio_drive_strength = GPIO_DRIVE_STRENGTH_2MA,
        .use_card_detect = false,
        .card_detect_gpio = SD_DETECT,

        // State variables:
        .m_Status = STA_NOINIT
    }
};

/* ********************************************************************** */
size_t sd_get_num() { return count_of(sd_cards); }
sd_card_t *sd_get_by_num(size_t num) {
    if (num <= sd_get_num()) {
        return &sd_cards[num];
    } else {
        return NULL;
    }
}
size_t spi_get_num() { return count_of(spis); }
spi_t *spi_get_by_num(size_t num) {
    if (num <= sd_get_num()) {
        return &spis[num];
    } else {
        return NULL;
    }
}

sd_card_t* pSDCardReader;

void init_sd() {
    time_init();

    // See FatFs - Generic FAT Filesystem Module, "Application Interface",
    // http://elm-chan.org/fsw/ff/00index_e.html
    pSDCardReader = sd_get_by_num(0);
    set_spi_dma_irq_channel(/* useChannel1: */ true, /* shared: */ true);
}
