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
    input  logic reset,
    input  logic clk,
    input  logic din,
    output logic dout = 1'b0
);
    logic din_1;  // metastable
    logic din_2;
    logic din_3;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            dout <= 1'b0;
            din_1 <= 1'b0;
            din_2 <= 1'b0;
            din_3 <= 1'b0;
        end else begin
            dout <= din_3 == 1'b0 && din_2 == 1'b1;
            
            din_1 <= din;
            din_2 <= din_1;
            din_3 <= din_2;
        end
    end
endmodule
