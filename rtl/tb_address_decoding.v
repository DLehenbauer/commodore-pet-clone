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
    reg clk         = 0;
    reg [16:0] addr = 0;
    reg rw_b        = 0;

    wire ram_enable;
    wire pia1_enable;
    wire pia2_enable;
    wire via_enable;
    wire crtc_enable;
    wire io_enable;
    wire mirror_enable;
    wire write_enable;

    address_decoding address_decoding(
        .clk(clk),
        .addr(addr),
        .rw_b(rw_b),
        .ram_enable(ram_enable),
        .pia1_enable(pia1_enable),
        .pia2_enable(pia2_enable),
        .via_enable(via_enable),
        .crtc_enable(crtc_enable),
        .io_enable(io_enable),
        .mirror_enable(mirror_enable),
        .write_enable(write_enable)
    );

    task check(
        input expected_ram_enable,
        input expected_pia1_enable,
        input expected_pia2_enable,
        input expected_via_enable,
        input expected_crtc_enable,
        input expected_io_enable,
        input expected_mirror_enable,
        input expected_write_enable
    );
        if (ram_enable != expected_ram_enable) begin
            $display("[%t] 'ram_enable' must be %d, but got %d.", $time, expected_ram_enable, ram_enable);
            $stop;
        end

        if (pia1_enable != expected_pia1_enable) begin
            $display("[%t] 'pia1_enable' must be %d, but got %d.", $time, expected_pia1_enable, pia1_enable);
            $stop;
        end

        if (pia2_enable != expected_pia2_enable) begin
            $display("[%t] 'pia2_enable' must be %d, but got %d.", $time, expected_pia2_enable, pia2_enable);
            $stop;
        end

        if (via_enable != expected_via_enable) begin
            $display("[%t] 'via_enable' must be %d, but got %d.", $time, expected_via_enable, via_enable);
            $stop;
        end

        if (crtc_enable != expected_crtc_enable) begin
            $display("[%t] 'crtc_enable' must be %d, but got %d.", $time, expected_crtc_enable, crtc_enable);
            $stop;
        end

        if (io_enable != expected_io_enable) begin
            $display("[%t] 'io_enable' must be %d, but got %d.", $time, expected_io_enable, io_enable);
            $stop;
        end

        if (mirror_enable != expected_mirror_enable) begin
            $display("[%t] 'mirror_enable' must be %d, but got %d.", $time, expected_mirror_enable, mirror_enable);
            $stop;
        end

        if (write_enable != expected_write_enable) begin
            $display("[%t] 'write_enable' must be %d, but got %d.", $time, expected_write_enable, write_enable);
            $stop;
        end
    endtask

    task check_range(
        input string name,
        input [16:0] start_addr,
        input [16:0] end_addr,
        input expected_ram_enable,
        input expected_pia1_enable,
        input expected_pia2_enable,
        input expected_via_enable,
        input expected_crtc_enable,
        input expected_io_enable,
        input expected_mirror_enable,
        input expected_write_enable
    );
        $display("%s: $%x-$%x", name, start_addr, end_addr);

        for (addr = start_addr; addr <= end_addr; addr = addr + 1) begin
            rw_b = 0;

            @(posedge clk);
            #1 check(
                expected_ram_enable,
                expected_pia1_enable,
                expected_pia2_enable,
                expected_via_enable,
                expected_crtc_enable,
                expected_io_enable,
                expected_mirror_enable,
                /* expected_write_enable: */ 0
            );

            rw_b = 1;

            @(posedge clk);
            #1 check(
                expected_ram_enable,
                expected_pia1_enable,
                expected_pia2_enable,
                expected_via_enable,
                expected_crtc_enable,
                expected_io_enable,
                expected_mirror_enable,
                expected_write_enable
            );
        end
    endtask

    initial begin
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end
    end

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        check_range(
            /* name:       */ "RAM",
            /* start_addr: */ 'h0000,
            /* end_addr:   */ 'h7fff,
            /* expected_ram_enable    : */ 1,
            /* expected_pia1_enable   : */ 0,
            /* expected_pia2_enable   : */ 0,
            /* expected_via_enable    : */ 0,
            /* expected_crtc_enable   : */ 0,
            /* expected_io_enable     : */ 0,
            /* expected_mirror_enable : */ 0,
            /* expected_write_enable  : */ 1
        );

        check_range(
            /* name:       */ "Display RAM",
            /* start_addr: */ 'h8000,
            /* end_addr:   */ 'h8fff,
            /* expected_ram_enable    : */ 1,
            /* expected_pia1_enable   : */ 0,
            /* expected_pia2_enable   : */ 0,
            /* expected_via_enable    : */ 0,
            /* expected_crtc_enable   : */ 0,
            /* expected_io_enable     : */ 0,
            /* expected_mirror_enable : */ 1,
            /* expected_write_enable  : */ 1
        );

        check_range(
            /* name:       */ "ROM",
            /* start_addr: */ 'h9000,
            /* end_addr:   */ 'he7ff,
            /* expected_ram_enable    : */ 1,
            /* expected_pia1_enable   : */ 0,
            /* expected_pia2_enable   : */ 0,
            /* expected_via_enable    : */ 0,
            /* expected_crtc_enable   : */ 0,
            /* expected_io_enable     : */ 0,
            /* expected_mirror_enable : */ 0,
            /* expected_write_enable  : */ 0
        );

        check_range(
            /* name:       */ "PIA1",
            /* start_addr: */ 'he810,
            /* end_addr:   */ 'he81f,
            /* expected_ram_enable    : */ 0,
            /* expected_pia1_enable   : */ 1,
            /* expected_pia2_enable   : */ 0,
            /* expected_via_enable    : */ 0,
            /* expected_crtc_enable   : */ 0,
            /* expected_io_enable     : */ 1,
            /* expected_mirror_enable : */ 0,
            /* expected_write_enable  : */ 1
        );

        check_range(
            /* name:       */ "PIA2",
            /* start_addr: */ 'he820,
            /* end_addr:   */ 'he83f,
            /* expected_ram_enable    : */ 0,
            /* expected_pia1_enable   : */ 0,
            /* expected_pia2_enable   : */ 1,
            /* expected_via_enable    : */ 0,
            /* expected_crtc_enable   : */ 0,
            /* expected_io_enable     : */ 1,
            /* expected_mirror_enable : */ 0,
            /* expected_write_enable  : */ 1
        );

        check_range(
            /* name:       */ "VIA",
            /* start_addr: */ 'he840,
            /* end_addr:   */ 'he87f,
            /* expected_ram_enable    : */ 0,
            /* expected_pia1_enable   : */ 0,
            /* expected_pia2_enable   : */ 0,
            /* expected_via_enable    : */ 1,
            /* expected_crtc_enable   : */ 0,
            /* expected_io_enable     : */ 1,
            /* expected_mirror_enable : */ 0,
            /* expected_write_enable  : */ 1
        );

        check_range(
            /* name:       */ "CRTC",
            /* start_addr: */ 'he880,
            /* end_addr:   */ 'he8ff,
            /* expected_ram_enable    : */ 0,
            /* expected_pia1_enable   : */ 0,
            /* expected_pia2_enable   : */ 0,
            /* expected_via_enable    : */ 0,
            /* expected_crtc_enable   : */ 1,
            /* expected_io_enable     : */ 1,
            /* expected_mirror_enable : */ 0,
            /* expected_write_enable  : */ 1
        );

        check_range(
            /* name:       */ "ROM",
            /* start_addr: */ 'hf000,
            /* end_addr:   */ 'hffff,
            /* expected_ram_enable    : */ 1,
            /* expected_pia1_enable   : */ 0,
            /* expected_pia2_enable   : */ 0,
            /* expected_via_enable    : */ 0,
            /* expected_crtc_enable   : */ 0,
            /* expected_io_enable     : */ 0,
            /* expected_mirror_enable : */ 0,
            /* expected_write_enable  : */ 0
        );

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule