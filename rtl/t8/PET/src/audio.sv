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

module delta_sigma_dac(
    input  logic               clk_i,
    input  logic               reset_i,
    input  logic signed [15:0] dac_i,
    output logic               dac_o
);
    // Convert signed 16-bit input to unsigned biased.
    wire  [15:0] s16         = dac_i + 16'h8000;
    logic [16:0] accumulator = '0;

    always_ff @(posedge clk_i) begin
        if (reset_i) accumulator <= '0;
        else accumulator <= accumulator[15:0] + s16;
    end

    assign dac_o = accumulator[16];
endmodule

module audio(
    input  logic       reset_i,
    input  logic       clk8_i,
    input  logic       diag_i,
    input  logic       via_cb2_i,
    output logic       audio_o
);
    wire signed [15:0] cb2_out = via_cb2_i && diag_i
        ? 16'h800
        : -16'h800;

    wire signed [15:0] mixed = cb2_out;

    delta_sigma_dac dac(
        .clk_i(clk8_i),
        .reset_i(reset_i),
        .dac_i(mixed),
        .dac_o(audio_o)
    );
endmodule
