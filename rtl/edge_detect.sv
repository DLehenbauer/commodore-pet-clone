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

module edge_detect(
    input clk,
    input reset,
    input din,
    output reg pe
);
    reg [2:0] history = 3'b0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            history <= 3'b0;
            pe <= 1'b0;
        end 
        else begin
            history <= { history[1:0], din };
            pe <= history[1] && !history[2];  
        end
    end
endmodule
