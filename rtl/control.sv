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
    input pi_write,
    input [16:0] pi_addr,
    input [7:0] pi_data,
    output res_b,
    output rdy
);
    localparam RES_B = 0,
               RDY   = 1;

    reg [1:0] state = 2'b00;

    always @(negedge pi_write) begin
        if (pi_addr === 16'hE80F) state <= pi_data[1:0];
    end
    
    assign res_b = state[RES_B];
    assign rdy   = state[RDY];
endmodule
