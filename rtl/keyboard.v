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
 
 module keyboard(
    input [15:0] pi_addr,
    input [7:0]  pi_data,
    input pi_write,

    input [1:0] bus_addr,
    input [7:0] bus_data_in,
    input bus_rw_b,

    input pia1_enabled_in,
    input io_read,
    input cpu_write,

    output reg [7:0] kbd_data_out = 8'hff,
    output kbd_enable
);
    reg [7:0] kbd_matrix [9:0];
    reg [3:0] current_kbd_row = 4'h0;

    always @(negedge pi_write) begin
        if (17'hE800 <= pi_addr && pi_addr <= 17'hE809) begin
            kbd_matrix[pi_addr[3:0]] <= pi_data;
        end
    end

    localparam PORTA = 2'd0,
               CRA   = 2'd1,
               PORTB = 2'd2,
               CRB   = 2'd3;

    wire writing_port_a = cpu_write && pia1_enabled_in && bus_addr == PORTA;

    // Save the selected keyboard row when the CPU writes to port A ($E810)
    always @(negedge writing_port_a) begin
        current_kbd_row = bus_data_in[3:0];
    end

    wire reading_port_b = io_read && pia1_enabled_in && bus_addr == PORTB;

    always @(posedge reading_port_b) begin
        kbd_data_out <= kbd_matrix[current_kbd_row];
    end

    // Intercept reads to port B ($E812) only when the cached key matrix has a pressed key.
    // Otherwise, reads should go to PIA1 so that the standard PET keyboard also works.
    assign kbd_enable = reading_port_b && kbd_data_out != 8'hff;
endmodule