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

module crtc(
    input reset,

    input            crtc_select,
    input     [16:0] bus_addr,
    input      [7:0] bus_data_in,
    input            cpu_write,

    input [15:0]     pi_addr,               // A0..4 select CRTC registers R0..17
    input  [7:0]     pi_data_in,
    input            pi_read,
    input            pi_write,

    output reg [7:0] crtc_data_out,
    output           crtc_data_out_enable,

    output reg [4:0] crtc_address_register,  // Internally selects R0..17.  Exposed for testing.
    output     [7:0] crtc_r                  // Contents of currently selected R0..17.  Exposed for testing.
);
    reg [7:0] r [16:0];

    assign crtc_r = r[crtc_address_register];

    always @(negedge cpu_write or posedge reset) begin
        if (reset) begin
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
        end else begin
            if (crtc_select) begin
                // 'crtc_select' is high when the bus address is in the $E8xx range.  Even addresses
                // map to CRTC register 0 and odd addresses are CRTC register 1.
                if (bus_addr[0]) r[crtc_address_register] <= bus_data_in;
                else crtc_address_register <= bus_data_in[4:0];
            end
        end
    end

    wire pi_crtc_select = 16'he8f0 <= pi_addr && pi_addr <= 16'he8ff;
    wire [4:0] pi_crtc_reg = { 1'b0, pi_addr[3:0] };

    // Update 'crtc_data_out' on the rising edge of pi_read so it is available when 'pi_data_reg'
    // is updated on the falling edge.
    always @(posedge pi_read) begin
        if (pi_crtc_select) begin
            crtc_data_out <= r[pi_crtc_reg];
        end
    end

    assign crtc_data_out_enable = pi_crtc_select;
endmodule