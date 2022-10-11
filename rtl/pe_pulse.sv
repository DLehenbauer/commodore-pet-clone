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

module pe_pulse (
    input reset,
    input clk,
    input din,
    output reg dout = 1'b0
);
    reg [1:0] history = 2'b00;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            history <= 2'b00;
            dout <= 1'b0;
        end else begin
            dout <= history[0] & ~history[1];
            history <= { history[0], din };
        end
    end
endmodule