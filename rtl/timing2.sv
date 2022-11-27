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

module timing2(
    input  logic clk_16_i,
    output logic clk_8_o = '0,
    output logic clk_cpu_o,
    input  logic spi_valid_i,
    output logic spi_enable_o,
    output logic spi_ready_o,
    output logic video_ram_enable_o,
    output logic video_rom_enable_o,
    input  logic cpu_valid_i,
    output logic cpu_select_o,
    output logic cpu_enable_o
);
    // Generate two 8 MHz clocks that are offset by 270 degrees:
    //
    //   'clk_8n' rotates ownership of the bus in round robin fashion.
    //   'clk_8p' is the bus clock.
    //
    // Note that 'clk_8p' pulses are centered between enable transitions, creating ~31ns
    // of setup/hold time.
    //
    //               1 . 3 . 5 . 7 . 9 .11 .13 .15 .17 .19 .21 .23 .25 .27 .29 .31 . 1 .
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //     clk_16   _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //     clk_8n   ‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //     enable   ​̅_​̅_​̅_​0̅​̅_​̅_​̅_X​_​̅_​̅_​̅1​̅_​̅_​̅_X_​̅_​̅_​̅2​̅_​̅_​̅_X_​̅_​̅_​̅3​̅_​̅_​̅_X_​̅_​̅_​̅4​̅_​̅_​̅_X_​̅_​̅_​̅5​̅_​̅_​̅_X_​̅_​̅_​̅6​̅_​̅_​̅_X_​̅_​̅_​̅7​̅_​̅_​̅_X_​̅_​̅_​̅0 
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //     clk_8p   _/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾
    //
    // Note: edge # = count * 2 + 1
    //       { rise edge #, fall edge #, rise edge # + 32 }

    logic clk_8n = 1'b1;
    always_ff @(posedge clk_16_i) clk_8_o <= ~clk_8_o;
    always_ff @(negedge clk_16_i) clk_8n  <= ~clk_8_o;

    // We initialize enable 8'b00000001 and rotate left on each positive edge of 'clk_8n'.
    //
    //                16   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     clk_8n   ‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    enable0   ‾‾‾‾‾‾‾\_______________________________________________________/‾‾‾‾
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    enable1   _______/‾‾‾‾‾‾‾\____________________________________________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    enable2   _______________/‾‾‾‾‾‾‾\____________________________________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    enable3   _______________________/‾‾‾‾‾‾‾\____________________________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    enable4   _______________________________/‾‾‾‾‾‾‾\____________________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    enable5   _______________________________________/‾‾‾‾‾‾‾\____________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    enable6   _______________________________________________/‾‾‾‾‾‾‾\____________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    enable7   _______________________________________________________/‾‾‾‾‾‾‾\____

    logic [7:0] enable_d, enable = 8'h01;

    always_comb begin
        enable_d = { enable[6:0], enable[7] };
    end
    
    always_ff @(posedge clk_8n) begin
        spi_enable_o <= spi_valid_i  && enable_d[0];
        spi_ready_o  <= spi_enable_o;
        cpu_select_o <= cpu_valid_i  && (enable_d[6] || enable_d[7]);
        cpu_enable_o <= cpu_select_o && enable_d[7];
        enable       <= enable_d;
    end

    assign video_ram_enable_o  = enable[1];
    assign video_rom_enable_o  = enable[2];
    
    // Generate 'clk_cpu' for the 6502:
    //
    //               1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16   1
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     clk_8p   _/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    // cpu_enable   _______________________________________________________/‾‾‾‾‾‾‾\____
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //    clk_cpu   _________________________________________________________/‾‾‾\______

    assign clk_cpu_o = clk_8_o & cpu_enable_o;
endmodule
