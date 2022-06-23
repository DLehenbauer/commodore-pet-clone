/**
 * PET Clone - Open hardware implementation of the Commodore PET
 * by Daniel Lehenbauer (and contributors).
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
 
 module pia1(
    input  [16:0] addr,
    input  [7:0]  data_in,
    output [7:0]  data_out,
    input  res_b,
    input  cpu_read_strobe,
    input  cpu_write_strobe,
    input  pi_write_strobe,
    output oe
);
    reg [7:0] kbd_matrix [10:0];
    reg [3:0] selected_kbd_row = 4'h0;

    // Save the selected keyboard row when the CPU writes to port A ($E810)
    always @(negedge cpu_write_strobe)
        if (addr == 17'hE810)
            selected_kbd_row = data_in[3:0];

    // Update our cached keyboard matrix when the RPi writes to $E800..E809.
    always @(negedge pi_write_strobe)
        if (17'hE800 <= addr && addr <= 17'hE809)
            kbd_matrix[addr[3:0]] = data_in;

    // Intercept reads to port B ($E812) when the cached key matrix has a pressed key.
    // Otherwise, enable data from the PIA.
    assign oe = !(cpu_read_strobe && addr == 17'hE812 && data_out != 8'hff);

    assign data_out = kbd_matrix[selected_kbd_row];
endmodule