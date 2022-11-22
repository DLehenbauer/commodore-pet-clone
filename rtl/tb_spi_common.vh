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

bit clk_sys;

initial begin
    clk_sys = 0;
    forever begin
        #31.25 clk_sys = ~clk_sys;
    end
end

bit start_sclk = 1'b0;
bit spi_sclk = 1'b0;

always @(posedge start_sclk) begin
    while (start_sclk) begin
        #250
        spi_sclk <= 1'b1;
        #500;
        spi_sclk <= 1'b0;
        #250;
    end
end

bit spi_cs_n = 1'b1;

task begin_xfer(
    input byte tx
);
    // MSB of 'tx_byte' is preloaded while spi_cs_n is high on rising edge of clk_sys.
    tx_byte = tx;
    @(posedge clk_sys);

    spi_cs_n = 0;
    #500;
    start_sclk = 1'b1;
endtask

integer bit_index;

task xfer_bits(
    input logic [7:0] next_tx = 8'hxx,
    input integer num_bits = 8
);
    for (bit_index = 0; bit_index < num_bits; bit_index++) begin
        @(posedge spi_sclk);

        // 'tx_byte' is loaded on falling edge of spi_sclk when the last bit is transfered.
        // However, we update 'tx_byte' after every bit to verify that 'tx_byte' is held
        // between loads.
        tx_byte = next_tx;
    end
endtask

task end_xfer;
    start_sclk = 0;

    #500;
    spi_cs_n = 1;

    #500;
endtask

logic       spi_rx;
logic       tx_valid;
logic [7:0] tx_byte = 8'hxx;

spi_byte spi_byte_tx(
    .clk_sys_i(clk_sys),
    .spi_sclk_i(spi_sclk),
    .spi_cs_ni(spi_cs_n),
    .spi_tx_o(spi_rx),
    .tx_byte_i(tx_byte),
    .valid_o(tx_valid)
);
