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
    output clk8,
    output pi_select,
    output pi_strobe,
    output cpu_select,
    output io_select,
    output cpu_strobe
);
    // count         0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  0
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :  
    //      clk16   _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //  pi_select   _/‾‾‾‾‾‾‾‾‾‾‾\___________________________________________________/‾‾‾
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //  pi_strobe   _____/‾‾‾\___________________________________________________________
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    // cpu_select   _________________________________________________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    //  io_select   _____________________________________________________/‾‾‾‾‾‾‾‾‾‾‾\___
    //               :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :   :
    // cpu_strobe   _________________________________________________________/‾‾‾\_______
    //
    // Note: Conversion to clock:
    //
    //       edge # = count * 2 + 1
    //       { rise edge #, fall edge #, rise edge # + 32}

    localparam [4:0] PI_SELECT  = 5'b00001,
                     PI_STROBE  = 5'b00011,
                     CPU_SELECT = 5'b00100,
                     IO_SELECT  = 5'b01100,
                     CPU_STROBE = 5'b11100;

    reg [3:0] count = 0;
    reg [4:0] state = PI_SELECT, next = PI_SELECT;

    
    always @(posedge clk16) begin
        count <= count + 4'h1;
        state <= next;
    end
    
    always @(count) begin
        next = 5'bxxxxx;
        case (count)
            0: next = PI_SELECT;
            1: next = PI_STROBE;
            2: next = PI_SELECT;
            3: next = 0;
            4: next = 0;
            5: next = 0;
            6: next = 0;
            7: next = 0;
            8: next = 0;
            9: next = 0;
            10: next = 0;
            11: next = 0;
            12: next = CPU_SELECT;
            13: next = IO_SELECT;
            14: next = CPU_STROBE;
            15: next = IO_SELECT;
        endcase
    end

    assign pi_select  = state[0];
    assign pi_strobe  = state[1];
    assign cpu_select = state[2];
    assign io_select  = state[3];
    assign cpu_strobe = state[4];

    assign clk8 = count[0];
endmodule