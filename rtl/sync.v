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

//        clk16  /‾\_/‾\_/‾\_/‾\_/‾\_/‾\_
//               :   :   :   :   :   :   
//      pending  __/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_____  Async signal that transfer is pending
//               :   :   :   :   :   :   
//       select  ____/‾‾‾‾‾‾‾‾‾‾‾\_______  Our turn to use bus: setup source/destination
//               :   :   :   :   :   :   
//       enable  ________/‾‾‾\___________  Perform the read or write
//               :   :   :   :   :   :   
//       strobe  ________/‾‾‾\___________  Generate the read or write strobe (only if transfer is in progress)
//               :   :   :   :   :   :   
//         done  ________________/‾‾‾\___  Signal that transfer is complete
//
// Notes:
//  - 'pending' must be signaled 1-cycle before 'enable' (posedge of select) so that we have
//    incoming signals (e.g., addr) in advance to setup the appropriate chips (RAM, I/O, etc.)
//
//  - Similarly, we must hold 'select' (and delay 'done') by 1-cycle after 'enable' so that our
//    incoming signals (e.g., addr) are held while we capture output on negedge 'enable'.  This
//    also gives our output a chance to propagate before the external device attempts to read.
module sync (
    input select,
    input enable,
    input pending,
    output strobe,
    output reg done = 0
);
    reg ready = 0;

    always @(posedge select or negedge pending) begin
        if (!pending) ready <= 0;
        else ready <= 1'b1;
    end

    always @(negedge select or negedge pending) begin
        if (!pending) done <= 0;
        else done <= ready;
    end

    assign strobe = enable && ready && !done;
endmodule
