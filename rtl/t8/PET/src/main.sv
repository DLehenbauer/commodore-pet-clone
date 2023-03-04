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
    output logic spi1_tx_o,
    output logic spi_ready_o,

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
    output logic cpu_res_o,
    output logic cpu_ready_o,
    output logic cpu_be_o,

    // RAM
    output logic ram_ce_o,
    output logic ram_oe_o,
    output logic ram_we_o,
    output logic [11:10] ram_addr_o,

    // I/O
    output logic pia1_cs_o,
    output logic pia2_cs_o,
    output logic via_cs_o,
    output logic io_oe_o,

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
    assign cpu_res_o    = '0;
    assign cpu_be_o     = '0;

    assign io_oe_o      = '0;
    assign pia1_cs_o    = '0;
    assign pia2_cs_o    = '0;
    assign via_cs_o     = '0;

    // Protocol for SPI1 peripheral
    logic spi_valid, spi_ready;

    logic [7:0] spi_rd_data;
    
    spi1 spi1(
        .clk_sys_i(clk16_i),
        .spi_sck_i(spi1_sck_i),
        .spi_cs_ni(spi1_cs_ni),
        .spi_rx_i(spi1_rx_i),
        .spi_tx_o(spi1_tx_o),
        .spi_valid_o(spi_valid),
        .spi_ready_i(spi_ready),
        .spi_ready_o(spi_ready_o),
        .spi_addr_o(bus_addr_o),
        .spi_data_i(spi_rd_data),
        .spi_data_o(bus_data_o),
        .spi_rw_no(bus_rw_no)
    );

    logic spi_en;
    logic clk8;

    timing timing(
        .clk16_i(clk16_i),
        .clk8_o(clk8),
        .spi_enable_o(spi_en),
        .spi_valid_i(spi_valid),
        .spi_ready_o(spi_ready)
    );
    
    wire spi_rd_en = spi_en & bus_rw_no;
    
    always @(negedge clk8) begin
        if (spi_rd_en) spi_rd_data <= bus_data_i;
    end

    assign ram_ce_o = 1'b1;
    assign ram_oe_o = bus_rw_no;            // RAM only drives data when FPGA/CPU are reading from bus
    assign ram_we_o = spi_en & !bus_rw_no;
    
    assign bus_addr_oe  = 1'b1;
    assign bus_data_oe  = !bus_rw_no;       // FPGA only drives data when writing to bus
    assign bus_rw_noe   = 1'b1;

    assign ram_addr_o[11:10] = bus_addr_o[11:10];
endmodule
