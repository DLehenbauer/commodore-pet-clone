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
        .cpu_write(cpu_write),

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

    task pi_load(
        input [4:0] r,
        input [7:0] expected_value
    );
        pi_addr = 16'he8f0 | r;

        #1 pi_read = 1'b1;
        assert_equal(crtc_data_out_enable, 1, "crtc_data_out_enable");

        #1 pi_read = 0;
        assert_equal(crtc_data_out, expected_value, "crtc_data_out");
        assert_equal(crtc_data_out_enable, 1, "crtc_data_out_enable");

        #1 pi_addr = 16'h0;
    endtask

    integer r;
    reg [7:0] value;

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        #1 reset = 1;
        #1 reset = 0;

        for (r = 0; r <= 15; r++) begin
            #1 $display("[%t] Test: CPU select R%d", $time, r);
            cpu_select(/* r: */ r);

            value = 8'h80 | r;

            #1 $display("[%t] Test: CPU store R%d = $%x", $time, r, value);
            cpu_store(/* value: */ value);

            #1 $display("[%t] Test: Pi load R%d == $%x", $time, r, value);
            pi_load(r, value);
        end

        for (r = 16; r <= 17; r++) begin
            #1 $display("[%t] Test: CPU select R%d", $time, r);
            cpu_select(/* r: */ r);

            value = 8'h80 | r;

            #1 $display("[%t] Test: CPU store R%d = $%x", $time, r, value);
            cpu_store(/* value: */ value);
        end

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule