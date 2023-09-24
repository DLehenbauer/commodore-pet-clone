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
    input  logic clk_sys_i,

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
    input  logic cpu_res_i,
    output logic cpu_ready_o,
    output logic cpu_be_o,

    // RAM
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
    input  logic via_cb2_i,
    output logic audio_o,

    // Graphics
    input  logic gfx_i,
    output logic h_sync_o,
    output logic v_sync_o,
    output logic video_o
);
    // Drive nothing to avoid contention
    assign cpu_be_o    = '0;
    assign io_oe_o     = '0;
    assign ram_oe_o    = '0;
    
    // Deassert RES to turn off NSTATUS LED
    assign cpu_res_o   = 1'b0;

    logic [16:0] spi_addr;
    logic  [7:0] spi_rd_data;
    logic  [7:0] spi_wr_data;
    logic        spi_we;
    logic        spi_cycle;
    logic        spi_ack;

    spi1_master spi1(
        // SBA
        .sba_clk_i(clk_i),
        .sba_addr_o(spi_addr),
        .sba_rd_data_i(spi_rd_data),
        .sba_wr_data_o(spi_wr_data),
        .sba_we_o(spi_we),
        .sba_cycle_o(spi_cycle),
        .sba_ack_i(spi_ack),

        // SPI
        .spi_sck_i(spi_sck_i),
        .spi_cs_ni(spi_cs_ni),
        .spi_rx_i(spi_rx_i),
        .spi_tx_o(spi_tx_o),
        .spi_ready_o(spi_ready_o)
    );

    logic setup_en;
    logic capture_en;

    timing timing(
        .clk_sys_i(clk_sys_i),
        .setup_en_o(setup_en),
        .capture_en_o(capture_en)
    );

    always_ff @(posedge clk_i) begin
        if (setup_en) begin
            spi_ack <= 0;

            if (spi_cycle) begin
                bus_addr_o  <=  spi_addr;
                bus_rw_no   <= !spi_we;
                bus_data_o  <= spi_wr_data;

                bus_addr_oe <= 1'b1;
                bus_rw_noe  <= 1'b1;
                bus_data_oe <= spi_we;
            end
        end else if (capture_en) begin
            spi_rd_data <= bus_data_i;
            spi_ack     <= 1'b1;

            bus_addr_oe <= '0;
            bus_rw_noe  <= '0;
            bus_data_oe <= '0;
        end
    end
endmodule
