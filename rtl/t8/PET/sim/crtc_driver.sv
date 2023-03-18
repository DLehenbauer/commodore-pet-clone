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

module crtc_driver(
    input logic setup_clk_i,
    input logic strobe_clk_i,
    input logic cclk_i,
    output logic res_o,
    output logic cs_o,
    output logic rs_o,
    output logic rw_no,
    output logic [7:0] data_o
);
    task crtc_begin(
        input logic rs_i,
        input logic rw_ni,
        input logic [7:0] data_i = 8'hxx
    );
        @(posedge setup_clk_i);
        cs_o = 1'b1;
        rs_o = rs_i;
        rw_no = rw_ni;
        data_o = data_i;

        @(posedge strobe_clk_i);
    endtask

    task crtc_end;
        if (strobe_clk_i) @(negedge strobe_clk_i);

        #1;

        cs_o = '0;
        rw_no = 1'b1;
        data_o = 8'hxx;
    endtask

    task select(input logic [7:0] register);
        crtc_begin(/* rs: */ '0, /* rw_n: */ '0, /* data: */ register);
        crtc_end();
    endtask

    task write(input logic [7:0] data);
        crtc_begin(/* rs: */ '1, /* rw_n: */ '0, /* data: */ data);
        crtc_end();
    endtask

    // task assert(input logic [7:0] expected);
    //     crtc_begin(/* rs: */ '1, /* rw_n: */ '1);
        
    //     assert(crtc_data_o == expected) else begin
    //         $error("Selected CRTC register must be %d, but got %d.", expected, crtc_data);
    //         $finish;
    //     end

    //     crtc_end();
    // endtask

    task setup(
        input logic [7:0] values[]
    );
        integer i;

        foreach(values[i]) begin
            select(/* register: */ i);
            write(/* data: */ values[i]);
            //crtc_assert(/* expected: */ values[i]);
        end
    endtask

    task reset;
        @(negedge setup_clk_i);
        res_o = 1'b1;
        @(posedge setup_clk_i);
        @(negedge setup_clk_i);
        res_o = '0;
    endtask
endmodule
