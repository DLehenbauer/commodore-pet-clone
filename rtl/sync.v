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

module sync (
    input clk,
    input pending,
    output strobe,
    output reg done = 0
);
    reg ready = 0;

    always @(posedge clk or negedge pending) begin
        if (!pending) ready <= 0;
        else ready <= clk && pending;
    end

    always @(negedge clk or negedge pending) begin
        if (!pending) done <= 0;
        else done <= strobe && pending;
    end

    assign strobe = clk && pending && ready && !done;
endmodule
