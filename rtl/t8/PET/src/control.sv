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

module control(
    input  logic        clk_bus_i,
    input  logic [16:0] spi_addr_i,
    input  logic  [7:0] spi_data_i,
    input  logic        spi_wr_en_i,
    output logic        cpu_res_o,
    output logic        cpu_ready_o
);
    localparam RES_N = 0,
               READY = 1;

    logic [1:0] state = 2'b00;

    always @(posedge clk_bus_i) begin
        if (spi_wr_en_i) begin
            if (spi_addr_i == 16'hE80F) state <= spi_data_i[1:0];
        end
    end
    
    assign cpu_res_o   = !state[RES_N];
    assign cpu_ready_o = state[READY];
endmodule
