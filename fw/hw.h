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

#define SPI_INSTANCE spi1
#define SPI_SCK_PIN 14
#define SPI_TX_PIN 11
#define SPI_RX_PIN 12
#define SPI_CSN_PIN 13
#define SPI_READY_B_PIN 10
#define SPI_MHZ 2

#define SD_SPI_INSTANCE SPI_INSTANCE
#define SD_CLK_GP SPI_SCK_PIN
#define SD_CMD_GP SPI_TX_PIN
#define SD_DAT_GP SPI_RX_PIN
#define SD_CSN_GP 9
#define SD_DETECT 8

#define SPI0_SCK_GP 6
#define SPI0_TX_GP 7
#define SPI0_RX_GP 4
#define SPI0_CSN_GP 5
#define SPI0_MHZ 4

#define FPGA_CRESET_GP 26
#define FPGA_CLK_GP 15
