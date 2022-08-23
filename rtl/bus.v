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

module bus(
    input clk16,
    output pi_select,
    output pi_strobe,
    output cpu_select,
    output io_select,
    output cpu_strobe
);
    //               0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  0
    //                _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ 
    // clk16        _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
    //                ___     ___     ___     ___     ___     ___     ___     ___     ___
    // clk8         _|000|___|001|___|010|___|011|___|100|___|101|___|110|___|111|___|000
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //  pi_select   _/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________________________/‾‾‾
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //  pi_strobe   _________/‾‾‾‾‾‾‾\___________________________________________________
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    // cpu_select   _________________________________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //  io_select   _________________________________________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    // cpu_strobe   _________________________________________________/‾‾‾‾‾‾‾\___________

    reg [3:0] count = 0;

    always @(posedge clk16) begin
        count <= count + 4'h1;
    end

    assign pi_select  = !cpu_select;
    assign pi_strobe  = count[3:1] == 3'b001;
    assign cpu_select = count[3:3] == 1'b1;
    assign io_select  = cpu_select && count != 4'b1000;
    assign cpu_strobe = count[3:1] == 4'b110;
endmodule