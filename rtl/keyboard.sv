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
 
 module keyboard(
    input  logic clk_bus_i,
    input  logic reset_i,
 
    input  logic [16:0] spi_addr_i,
    input  logic  [7:0] spi_data_i,
    input  logic        spi_wr_en_i,

    input  logic [1:0] bus_addr_i,
    input  logic [7:0] bus_data_i,

    input  logic pia1_en_i,
    input  logic cpu_rd_en_i,
    input  logic cpu_wr_en_i,

    output logic [7:0] kbd_data_o = 8'hff,
    output logic kbd_en_o
);
    logic [7:0] kbd_matrix [9:0];   
    logic [3:0] current_kbd_row = '0;
    
    wire spi_wr_matrix = spi_wr_en_i && 17'hE800 <= spi_addr_i && spi_addr_i <= 17'hE809;
    
    always @(posedge clk_bus_i or posedge reset_i) begin
        if (reset_i) begin
            kbd_matrix[0] = 8'hff;
            kbd_matrix[1] = 8'hff;
            kbd_matrix[2] = 8'hff;
            kbd_matrix[3] = 8'hff;
            kbd_matrix[4] = 8'hff;
            kbd_matrix[5] = 8'hff;
            kbd_matrix[6] = 8'hff;
            kbd_matrix[7] = 8'hff;
            kbd_matrix[8] = 8'hff;
            kbd_matrix[9] = 8'hff;
        end else begin
            if (spi_wr_matrix) begin
                kbd_matrix[spi_addr_i[3:0]] <= spi_data_i;
            end
        end
    end

    localparam PORTA = 2'd0,
               CRA   = 2'd1,
               PORTB = 2'd2,
               CRB   = 2'd3;

    wire writing_port_a = cpu_wr_en_i && pia1_en_i && bus_addr_i == PORTA;

    // Save the selected keyboard row when the CPU writes to port A ($E810)
    always @(negedge clk_bus_i) begin
        if (writing_port_a) current_kbd_row = bus_data_i[3:0];
    end

    wire reading_port_b = cpu_rd_en_i && pia1_en_i && bus_addr_i == PORTB;

    always @(posedge clk_bus_i) begin
        if (reading_port_b) kbd_data_o <= kbd_matrix[current_kbd_row];
    end

    // Intercept reads to port B ($E812) only when the cached key matrix has a pressed key.
    // Otherwise, reads should go to PIA1 so that the standard PET keyboard also works.
    assign kbd_en_o = reading_port_b && kbd_data_o != 8'hff;
endmodule
