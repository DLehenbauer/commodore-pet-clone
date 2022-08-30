`timescale 1ns / 1ps

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

module tb();
    localparam PORTA = 2'd0,
               PORTB = 2'd2;

    reg [15:0] pi_addr  = 16'hxxxx;
    reg [7:0]  pi_data  = 8'hxx;
    reg pi_write_strobe = 0;

    reg [1:0]  bus_addr = 2'h0;
    reg [7:0]  bus_data_in = 8'h0;
    reg bus_rw_b = 0;

    reg io_select = 0;
    reg pia1_enabled_in = 0;
    reg cpu_write_strobe = 0;

    wire kbd_enable;
    wire [7:0] kbd_data_out;

    wire io_read = io_select && bus_rw_b;

    keyboard keyboard(
        .pi_addr(pi_addr),
        .pi_data(pi_data),
        .pi_write_strobe(pi_write_strobe),

        .bus_addr(bus_addr),
        .bus_data_in(bus_data_in),
        .bus_rw_b(bus_rw_b),

        .io_read(io_read),
        .cpu_write_strobe(cpu_write_strobe),
        .pia1_enabled_in(pia1_enabled_in),

        .kbd_data_out(kbd_data_out),
        .kbd_enable(kbd_enable)
    );

    task check(
        input expected_kbd_enable,
        input [7:0] expected_kbd_data_out
    );
        $display("[%t] CHECK %d %d", $time, kbd_enable, kbd_data_out);
        assert_equal(kbd_enable, expected_kbd_enable, "kbd_enable");
        assert_equal(kbd_data_out, expected_kbd_data_out, "kbd_data_out");
    endtask

    task set_key_row(
        input [9:0] row,
        input [7:0] value
    );
        pi_addr = 16'he800 + row;
        pi_data = value;
        
        #1;
        
        pi_write_strobe = 1;

        #1;
        
        pi_write_strobe = 0;
        
        #1;
        pi_addr = 16'hxxxx;
        pi_data = 8'hxx;
    endtask

    task read_key_row(
        input [3:0] row,
        input [7:0] expected_col
    );
        bus_addr = PORTA;
        bus_data_in = row;
        bus_rw_b = 1'b0;

        #1;

        io_select = 1;
        pia1_enabled_in = 1;

        #1;

        cpu_write_strobe = 1;

        #1;

        cpu_write_strobe = 0;

        #1;

        io_select = 0;
        pia1_enabled_in = 0;

        #1;

        bus_addr = PORTB;
        bus_data_in = 8'hxx;
        bus_rw_b = 1;

        #1; 

        io_select = 1;
        pia1_enabled_in = 1;

        #1;

        assert_equal(kbd_enable, 1, "kbd_enable");
        assert_equal(kbd_data_out, expected_col, "kbd_data_out");

        #1;

        io_select = 0;
        pia1_enabled_in = 0;

        #1;

        bus_addr = 2'bxx;
        bus_rw_b = 1'bx;

        #1;
    endtask

    initial begin
        integer row;
        integer col;

        $dumpfile("out.vcd");
        $dumpvars;

        col = 1;

        for (row = 0; row < 10; row++) begin
            #1 $display("[%t] Test: Pi sets row %d to %d", $time, row, col);

            set_key_row(row, col);
            read_key_row(row, col);

            col = (col << 1);
            if (col > 8'hff) col = 1;
        end

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule