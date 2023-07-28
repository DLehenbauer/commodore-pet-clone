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

module pwm(
    input logic reset_i,
    input logic clk_i,
    input logic [15:0] compare_i,
    output logic out_o
);
    logic [16:0] accumulator = '0;
    
    always_ff @(posedge clk_i) begin
        if (reset_i) accumulator <= '0;
        else accumulator <= accumulator[15:0] + compare_i;
    end

    assign out_o = accumulator[16];
endmodule

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
    input  logic       cpu_en_i,
    input  logic       sid_en_i,
    input  logic       cpu_wr_en_i,
    input  logic [4:0] addr_i,
    input  logic [7:0] data_i,      // writing to SID
    output logic [7:0] data_o,      // reading from SID

    input  logic       diag_i,
    input  logic       via_cb2_i,
    output logic       audio_o
);
    wire sid_wr_en = cpu_wr_en_i && sid_en_i;

    // See http://www.cbmhardware.de/show.php?r=14&id=71/PETSID
    logic signed [15:0] sid_out;

    sid#(.POT_SUPPORT(0)) sid(
        .clk(clk8_i),       // System clock
        .clkEn(cpu_en_i),   // 1 MHz clock enable
        .iRst(reset_i),     // sync. reset (active high)
        .iWE(sid_wr_en),    // write enable (active high)
        .iAddr(addr_i),     // sid address
        .iDataW(data_i),    // writing to SID
        .oDataR(data_o),    // reading from SID
        .oOut(sid_out)      // sid output
    );

    wire signed [15:0] cb2_out = via_cb2_i && diag_i
        ? 16'h800
        : -16'h800;

    wire signed [15:0] mixed = sid_out + cb2_out;

    delta_sigma_dac dac(
        .clk_i(clk8_i),
        .reset_i(reset_i),
        .dac_i(mixed),
        .dac_o(audio_o)
    );
endmodule
