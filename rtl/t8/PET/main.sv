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

module main(
    // FPGA
    input  logic clk16_i,

    // SPI1
    input  logic spi1_sck_i,
    input  logic spi1_cs_ni,
    input  logic spi1_rx_i,
    input  logic spi1_tx_i,
    output logic spi1_tx_o,
    output logic spi1_tx_oe,
    output logic spi_ready_no,

    // System Bus
    input  logic [15:0]  bus_addr_i,
    output logic [16:0]  bus_addr_o,
    output logic         bus_addr_oe,

    input  logic  [7:0]  bus_data_i,
    output logic  [7:0]  bus_data_o,
    output logic         bus_data_oe,

    input  logic         bus_rw_ni,
    output logic         bus_rw_no,
    output logic         bus_rw_noe,
   
    // CPU
    output logic cpu_clk_o,

    input  logic cpu_res_nai,
    output logic cpu_res_nao,
    output logic cpu_res_naoe,
    
    output logic cpu_ready_o,
    
    input  logic cpu_irq_ni,
    output logic cpu_irq_no,
    output logic cpu_irq_noe,

    input  logic cpu_nmi_ni,
    output logic cpu_nmi_no,
    output logic cpu_nmi_noe,

    output logic cpu_be_o,

    // RAM
    output logic ram_ce_no,
    output logic ram_oe_no,
    output logic ram_we_no,
    output logic [11:10] ram_addr_o,

    // I/O
    output logic pia1_cs2_no,
    output logic pia2_cs2_no,
    output logic via_cs2_no,
    output logic io_oe_no,

    // Audio
    input  logic diag_i,
    input  logic cb2_i,
    output logic audio_o,

    // Graphics
    input  logic gfx_i,
    output logic h_sync_o,
    output logic v_sync_o,
    output logic video_o
);
    assign cpu_be_o     = '0;
    assign bus_addr_oe  = '0;
    assign bus_data_oe  = '0;
    assign bus_rw_noe   = '0;
    assign cpu_irq_noe  = '0;
    assign cpu_nmi_noe  = '0;
    assign cpu_res_naoe = '0;

    assign io_oe_no     = 1'b1;
    assign pia1_cs2_no  = 1'b1;
    assign pia2_cs2_no  = 1'b1;
    assign via_cs2_no   = 1'b1;
    assign ram_ce_no    = 1'b1;
    assign ram_oe_no    = 1'b1;
    assign ram_we_no    = 1'b1;

    // Stub to unblock PnR
    always @(posedge clk16_i) begin
        cpu_clk_o = !cpu_clk_o;
    end
endmodule
