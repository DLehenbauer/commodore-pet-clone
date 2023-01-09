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

// Simple H/V sync generator @60 Hz.
module video1(
    input  logic clk_16_i,
    output logic h_sync_o,
    output logic v_sync_o
);
    logic [18:0] count = 0;
    
    // Bits 9:0 divide 16 MHz 'clk' by 1024 to get the H_Sync_o frequency of ~15.6 KHz
    assign h_sync_o = count[9];

    // Bits 18:10 count horizontal scan lines.  Bit 18 is high only momentarily before
    // we reach line 260 and reset the counter.  Therefore we use bit 17 to get a 60 Hz
    // V_Sync_o with a duty cycle of ~49.2%.
    
    localparam VBLANK = (19'd260 << 10);
    
    assign v_sync_o = count[17];
    
    always_ff @(posedge clk_16_i) begin
        if (count != (VBLANK - 1)) count <= count + 19'd1;
        else count <= 0;
    end
endmodule
