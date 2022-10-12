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

// sync signal to different clock domain
module sync2(
    input  logic reset,
    input  logic clk,
    input  logic din,
    output logic dout
);
    logic din1; // 1st stage ff output
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) { dout, din1 } <= '0;
        else { dout, din1 } <= { din1, din };
    end
endmodule

// Pulse Generator
module pulse(
    input logic reset,
    input logic clk,
    input logic din,
    output logic pulse,
    output logic dout
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) dout <= '0;
        else dout <= din;
    end

    assign pulse = dout ^ din;
endmodule

module pe_pulse (
    input  logic reset,
    input  logic clk,
    input  logic din,
    output logic dout
);
    logic dout1;

    sync2 sync2(
        .reset(reset),
        .clk(clk),
        .din(din),
        .dout(dout1)
    );

    pulse pulse(
        .reset(reset),
        .clk(clk),
        .din(dout1),
        .pulse(dout)
    );
endmodule
