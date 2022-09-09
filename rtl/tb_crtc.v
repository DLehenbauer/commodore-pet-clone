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

`timescale 1ns / 1ps

module tb();
    reg reset = 0;

    reg [16:0] bus_addr    = 17'hxxxxx;
    reg [7:0]  bus_data_in = 8'h0;
    reg        bus_rw_b    = 0;

    reg cpu_read = 0;
    reg cpu_write = 0;

    reg [15:0] pi_addr  = 16'hxxxx;
    reg [7:0]  pi_data  = 8'hxx;
    reg        pi_read = 0;

    wire [7:0] crtc_data_out;
    wire       crtc_data_out_enable;

    wire [4:0] crtc_address_register;
    wire [7:0] crtc_r;

    address_decoding address_decoding(
        .addr(bus_addr),
        .crtc_enable(crtc_enable)
    );

    crtc ctrc(
        .res_b(!reset),

        .crtc_select(crtc_enable),
        .bus_addr(bus_addr),
        .bus_data_in(bus_data_in),
        .write_strobe(cpu_write),

        .pi_addr(pi_addr),
        .pi_data_in(pi_data),
        .pi_read(pi_read),

        .crtc_data_out(crtc_data_out),
        .crtc_data_out_enable(crtc_data_out_enable),

        .crtc_address_register(crtc_address_register),
        .crtc_r(crtc_r)
    );

    task cpu_select(
        input [4:0] r
    );
        #1 bus_data_in = { 3'b000, r };
        #1 bus_addr = 17'he880;
        #1 cpu_write = 1'b1;
        #1 cpu_write = 0;

        assert_equal(crtc_address_register, r, "crtc_address_register");
    endtask

    task cpu_store(
        input [7:0] value
    );
        #1 bus_data_in = value;
        #1 bus_addr = 17'he881;
        #1 cpu_write = 1'b1;
        #1 cpu_write = 0;

        assert_equal(crtc_r, value, "crtc_r");
    endtask

    integer r;
    reg [7:0] value;

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 reset = 1;
        #1 reset = 0;

        for (r = 0; r <= 17; r++) begin
            #1 $display("[%t] Test: CPU select R%d", $time, r);
            cpu_select(/* r: */ r);
        end

        for (r = 0; r <= 17; r++) begin
            value = $random;
            #1 $display("[%t] Test: CPU store R%d = %d", $time, r, value);
            cpu_select(/* r: */ r);
            cpu_store(/* value: */ value);
        end

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule