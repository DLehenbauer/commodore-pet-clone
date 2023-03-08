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

module timing(
    input  logic clk16_i,
    output logic strobe_clk_o   = '0,
    output logic setup_clk_o    = 1'b1,
    output logic cpu_clk_o,
    output logic cpu_be_o       = '0,
    output logic cpu_en_o       = '0,
    input  logic spi_valid_i,
    output logic spi_en_o       = '0,
    output logic spi_ready_o    = 1'b1
);
    // Generate two 8 MHz clocks that are offset by 90 degrees:
    //
    //   'setup_clk' rotates ownership of the bus in round robin fashion.
    //   'strobe_clk' is the bus clock.
    //
    // Note that 'strobe_clk' pulses are centered between enable transitions, creating ~31ns
    // of setup/hold time.
    //
    //               1 . 3 . 5 . 7 . 9 .11 .13 .15 .17 .19 .21 .23 .25 .27 .29 .31 . 1 .
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //     clk_16   _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //  setup_clk   ‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //     enable   ​̅​_​̅_​̅_​̅0​̅_​̅_​̅_X​_​̅_​̅_​̅1​̅_​̅_​̅_X_​̅_​̅_​̅2​̅_​̅_​̅_X_​̅_​̅_​̅3​̅_​̅_​̅_X_​̅_​̅_​̅4​̅_​̅_​̅_X_​̅_​̅_​̅5​̅_​̅_​̅_X_​̅_​̅_​̅6​̅_​̅_​̅_X_​̅_​̅_​̅7​̅_​̅_​̅_X_​̅_​̅_​̅0 
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    // strobe_clk   _/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾
    //
    // Note: edge # = count * 2 + 1
    //       { rise edge #, fall edge #, rise edge # + 32 }

    always_ff @(posedge clk16_i) strobe_clk_o <= ~strobe_clk_o;
    always_ff @(negedge clk16_i) setup_clk_o  <= ~strobe_clk_o;

    // We initialize en[7:0] with 8'b00000001 and rotate left on each positive edge of 'setup_clk'.
    //
    //                16   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    // setup_clk   ‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     en[0]   ‾‾‾‾‾‾‾\_______________________________________________________/‾‾‾‾
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     en[1]   _______/‾‾‾‾‾‾‾\____________________________________________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     en[2]   _______________/‾‾‾‾‾‾‾\____________________________________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     en[3]   _______________________/‾‾‾‾‾‾‾\____________________________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     en[4]   _______________________________/‾‾‾‾‾‾‾\____________________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     en[5]   _______________________________________/‾‾‾‾‾‾‾\____________________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     en[6]   _______________________________________________/‾‾‾‾‾‾‾\____________
    //                 :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //     en[7]   _______________________________________________________/‾‾‾‾‾‾‾\____

    logic [7:0] en_d, en_q = 8'h01;

    always_comb begin
        en_d = { en_q[6:0], en_q[7] };
    end
    
    always_ff @(posedge setup_clk_o) begin
        spi_en_o     <= spi_valid_i && en_d[0];
        spi_ready_o  <= spi_en_o;
        cpu_be_o     <= en_d[6] || en_d[7];
        cpu_en_o     <= en_d[7];
        en_q         <= en_d;
    end
    
    // Generate 'cpu_clk' for the 6502:
    //
    //               1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16   1
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    // strobe_clk   _/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //     cpu_en   _______________________________________________________/‾‾‾‾‾‾‾\____
    //               : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
    //    cpu_clk   _________________________________________________________/‾‾‾\______

    assign cpu_clk_o = strobe_clk_o & cpu_en_o;
endmodule
