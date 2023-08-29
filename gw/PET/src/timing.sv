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

module timing(
    input  logic clk_sys_i,     // 64 MHz
    output logic clk_setup_o = '0,
    output logic clk_enable_o = '0,
    output logic clk_disable_o = '0,
    output logic cpu_clk_o = '0
);
    logic [5:0] counter = '0;
    wire  [2:0] enable = counter[5:3];

    always @(posedge clk_sys_i) begin
        counter <= counter + 1'b1;
        clk_setup_o   <= counter[2:0] == 3'b000;
        clk_enable_o  <= counter[2:0] == 3'b010;
        clk_disable_o <= counter[2:0] == 3'b110;
    end

    logic [7:0] en_d, en_q = 8'h01;

    always_comb begin
        en_d = { en_q[6:0], en_q[7] };
    end

    always_ff @(posedge clk_sys_i) begin
        if (clk_setup_o) en_q <= en_d;
        if (clk_enable_o) cpu_clk_o <= 1'b1;
        else if (clk_disable_o) cpu_clk_o <= '0;
    end
endmodule
