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
    // input  res_b,
    input  crtc_enabled,            // bus_addr is in the $E880-E8ff range
    // input      [0:0] bus_addr,      // A0 distinguishes R0 from R1
    // input      [7:0] bus_data_in,
    // output reg [7:0] bus_data_out,
    // input  io_read,
    // input  cpu_write,

    input      [4:0] pi_addr,       // A0..A4 select CRTC registers R0..R17
    input      [7:0] pi_data_in,
    output reg [7:0] pi_data_out,
    
    input pi_enabled,
    input pi_read,
    input pi_write
);
    reg [7:0] r [16:0];

    always @(negedge pi_read) begin
        if (crtc_enabled) begin
            pi_data_out <= r[pi_addr];
        end
    end

    always @(negedge pi_write) begin
        if (crtc_enabled) begin
            r[pi_addr] <= pi_data_in;
        end
    end
endmodule