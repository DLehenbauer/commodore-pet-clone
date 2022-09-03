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

// Simple H/V sync generator @60 Hz.
module hvSync(
    input clk16,
    output hsync,
    output vsync
);
    reg [18:0] count = 0;
    
    // Bits 9:0 divide 16 MHz 'clk' by 1024 to get the HSync frequency of ~15.6 KHz
    assign hsync = count[9];

    // Bits 18:10 count horizontal scan lines.  Bit 18 is high only momentarily before
    // we reach line 260 and reset the counter.  Therefore we use bit 17 to get a 60 Hz
    // VSync with a duty cycle of ~49.2%.
    
    localparam VBLANK = (19'd260 << 10);
    
    assign vsync = count[17];
    
    always @(posedge clk16) begin
        if (count != (VBLANK - 1)) count <= count + 19'd1;
        else count <= 0;
    end
endmodule

 
module crtc(
    input res_b,
    input     [15:0] pi_addr,       // A0..A4 select CRTC registers R0..R17
    input      [7:0] pi_data_in,   
    input pi_enabled,
    input pi_read,
    input pi_write,

    output reg [7:0] crtc_data_out,
    output crtc_data_out_enable
);
    reg [7:0] r [16:0];

    wire pi_crtc_select = 16'he8f0 <= pi_addr && pi_addr <= 16'he8ff;
    wire [3:0] pi_crtc_reg = pi_addr[3:0];

    always @(posedge pi_read) begin
        if (pi_crtc_select) begin
            crtc_data_out <= r[pi_crtc_reg];
        end
    end

    always @(negedge pi_write or negedge res_b) begin
        if (!res_b) begin
            r[0] = 8'h31;
            r[1] = 8'h28;
            r[2] = 8'h29;
            r[3] = 8'h0f;
            r[4] = 8'h28;
            r[5] = 8'h05;
            r[6] = 8'h19;
            r[7] = 8'h21;
            r[8] = 8'h00;
            r[9] = 8'h07;
            r[10] = 8'h00;
            r[11] = 8'h00;
            r[12] = 8'h10;
            r[13] = 8'h00;
            r[14] = 8'h00;
            r[15] = 8'h00;
            r[16] = 8'h00;
        end else if (pi_crtc_select) begin
            r[pi_crtc_reg] <= pi_data_in;
        end
    end

    assign crtc_data_out_enable = pi_crtc_select;
endmodule