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

reg sys_clk;

initial begin
    sys_clk = 0;
    forever begin
        #31.25 sys_clk = ~sys_clk;
    end
end

reg start_sclk = 1'b0;
reg spi_sclk = 1'b0;

always @(posedge start_sclk) begin
    while (start_sclk) begin
        #250
        spi_sclk <= 1'b1;
        #500;
        spi_sclk <= 1'b0;
        #250;
    end
end

reg [7:0] tx_byte;
wire tx_valid;

task begin_xfer;
    spi_cs_n = 0;
    #500;
    start_sclk = 1'b1;
endtask

integer bit_index;

task xfer_byte(
    input [7:0] data,
    input integer num_bits = 8
);
    tx_byte = data;

    for (bit_index = 0; bit_index < num_bits; bit_index++) begin
        @(posedge spi_sclk);
    end
endtask

task end_xfer;
    start_sclk = 0;
    tx_byte = 8'hxx;

    #500;
    spi_cs_n = 1;

    #500;
endtask
