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


//      _         _
//    _| |_______| |
//

module timing(
    input  logic clk_sys_i,     // 64 MHz
    output logic setup_en_o,
    output logic capture_en_o
);
    logic [5:0] counter = '0;

    always @(posedge clk_sys_i) begin
        counter      <= counter + 1'b1;
        setup_en_o   <= counter[2:0] == 3'b000;
        capture_en_o <= counter[2:0] == 3'b111;
    end
endmodule
