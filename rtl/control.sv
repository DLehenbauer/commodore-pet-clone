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

module pi_ctl(
    input  logic clk_i,
    input  logic spi_rw_n,
    input  logic [16:0] spi_addr_i,
    input  logic [7:0] spi_data_i,
    input  logic spi_enable_i,
    output logic cpu_res_no,
    output logic cpu_ready_o
);
    localparam RES_N = 0,
               READY = 1;

    logic [1:0] state = 2'b00;

    always @(posedge clk_i) begin
        if (spi_enable_i) begin
            if (spi_addr_i == 16'hE80F) state <= spi_data_i[1:0];
        end
    end
    
    assign cpu_res_no  = state[RES_N];
    assign cpu_ready_o = state[READY];
endmodule
