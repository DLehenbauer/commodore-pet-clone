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

module mock_mcu(
    output logic spi1_sck_o,
    output logic spi1_cs_no,
    output logic spi1_tx_o,
    input  logic spi1_rx_i,
    input  logic spi_ready_ni
);
    spi_driver spi1(
        .spi_sck_o(spi1_sck_o),
        .spi_cs_no(spi1_cs_no),
        .spi_tx_o(spi1_tx_o)
    );

    task reset;
        spi1.reset();
    endtask
endmodule
