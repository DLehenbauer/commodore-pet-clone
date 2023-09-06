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
    input logic clk_i,      // Sampling clock
    input logic data_i,     // Input signal to detect edges
    output logic pe_o,      // Output for rising edge detection
    output logic ne_o       // Output for falling edge detection
);
    logic [1:0] data = '0;

    always @(posedge clk_i) begin
        pe_o <= ( data[0] && !data[1]);
        ne_o <= (!data[0] &&  data[1]);
        data <= { data[0], data_i };
    end
endmodule
