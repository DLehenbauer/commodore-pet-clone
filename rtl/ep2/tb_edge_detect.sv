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
    reg reset;
    reg clk;
    reg din;
    wire pe;

    edge_detect edge_detect(
        .reset(reset),
        .clk(clk),
        .din(din),
        .pe(pe)
    );

    task check(
        input expected_pe
    );
        assert_equal(pe, expected_pe, "pe");
    endtask

    initial begin
        reset = 1'b1;
        check(/* pe: */ 1'b0);
    end
endmodule;