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
    output logic h_sync_o,
    output logic v_sync_o
);
    logic clk16 = '0;
    initial forever #(1000 / (16 * 2)) clk16 = ~clk16;

    logic strobe_clk;
    logic setup_clk;
    logic cpu_en;

    timing timing(
        .clk16_i(clk16),
        .strobe_clk_o(strobe_clk),
        .setup_clk_o(setup_clk),
        .cpu_en_o(cpu_en)
    );

    logic        res = '0;
    logic        cs = '0;
    logic        rw_n = 1'b1;
    logic        rs = '0;
    logic [7:0]  crtc_data_i = 8'hxx;
    logic [7:0]  crtc_data_o;
    logic        crtc_data_oe;
    logic        de;
    logic [13:0] ma;
    logic [4:0]  ra;

    crtc crtc(
        .reset_i(res),
        .strobe_clk_i(strobe_clk),      // Triggers data transfers on bus
        .setup_clk_i(setup_clk),        // Triggers data transfers on bus
        .cclk_en_i(cpu_en),             // Enables character clock (always 1 MHz)
        .cs_i(cs),                      // CRTC selected for data transfer (driven by address decoding)
        .rw_ni(rw_n),                   // Direction of date transfers (0 = writing to CRTC, 1 = reading from CRTC)
        .rs_i(rs),                      // Register select (0 = write address/read status, 1 = read addressed register)
        .data_i(crtc_data_i),           // Transfer data written from CPU to CRTC when CS asserted and /RW is low
        .data_o(crtc_data_o),           // Transfer data read by CPU from CRTC when CS asserted and /RW is high
        .data_oe(crtc_data_oe),         // Asserted when CPU is reading from CRTC
        .h_sync_o(h_sync_o),            // Horizontal sync
        .v_sync_o(v_sync_o),            // Vertical sync
        .de_o(de),                      // Display enable
        .ma_o(ma),                      // Refresh RAM address lines
        .ra_o(ra)                       // Raster address lines
    );
    
    wire cclk = setup_clk && cpu_en;

    task crtc_begin(
        input logic rs_i,
        input logic rw_n_i,
        input logic [7:0] data_i = 8'hxx
    );
        @(posedge cclk);
        cs = 1'b1;
        rs = rs_i;
        rw_n = rw_n_i;
        crtc_data_i = data_i;

        @(posedge strobe_clk);
    endtask

    task crtc_end();
        if (strobe_clk) @(negedge strobe_clk);

        #1;

        cs = '0;
        rw_n = 1'b1;
        crtc_data_i = 8'hxx;
    endtask

    task select(input logic [7:0] register);
        crtc_begin(/* rs: */ '0, /* rw_n: */ '0, /* data: */ register);
        crtc_end();
    endtask;

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
        @(negedge setup_clk);
        res = 1'b1;
        @(posedge setup_clk);
        @(negedge setup_clk);
        res = '0;
    endtask
endmodule