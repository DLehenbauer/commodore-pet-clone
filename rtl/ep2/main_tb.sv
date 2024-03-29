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

`timescale 1ns / 1ps

module tb();
    logic clk_16_i = 0;
    initial forever #31.25 clk_16_i = ~clk_16_i;

    logic        spi_sclk;
    logic        spi_cs_n;
    logic        spi_rx;
    logic        spi_tx;

    logic [16:0] spi_addr;
    logic  [7:0] spi_rd_data;
    logic  [7:0] spi_wr_data;
    logic        spi_rw_n;
    logic        spi_valid;
    logic        spi_ready_in;
    logic        spi_ready_out;

    spi_bridge_driver driver (
        .clk_sys_i(clk_16_i),

        .spi_sclk_o(spi_sclk),
        .spi_cs_no(spi_cs_n),
        .spi_rx_o(spi_rx),

        .spi_addr_o(spi_addr),
        .spi_data_i(spi_rd_data),
        .spi_data_o(spi_wr_data),
        .spi_rw_no(spi_rw_n),
        .spi_valid_o(spi_valid),
        .spi_ready_i(spi_ready_in),
        .spi_ready_o(spi_ready_out)
    );

    logic [7:0]   debug_o;
    wire          bus_rw_nio;
    wire  [16:0]  bus_addr_io;
    wire   [7:0]  bus_data_io;
    logic [11:10] ram_addr_o;
    logic spi_pending_ni;
    logic spi_ready_no;
    logic clk_cpu_o;
    logic ram_oe_no;
    logic ram_we_no;
    logic cpu_res_ai = '0;
    logic cpu_res_nao;
    logic cpu_ready_o;
    logic cpu_sync_i;
    logic cpu_en_o;
    logic ram_ce_no;
    logic pia1_cs2_no;
    logic pia2_cs2_no;
    logic via_cs2_no;
    logic io_oe_no;
    logic gfx_i;
    logic h_sync_o;
    logic v_sync_o;
    logic video_o;

    main main(
        .debug_o(debug_o),

        // System Bus
        .bus_rw_nio(bus_rw_nio),
        .bus_addr_io(bus_addr_io),
        .bus_data_io(bus_data_io),        
        .ram_addr_o(ram_addr_o),

        // SPI
        .spi_sclk_i(spi_sclk),
        .spi_cs_ni(spi_cs_n),
        .spi_rx_i(spi_rx),
        .spi_tx_io(spi_tx),
        .spi_ready_no(spi_ready_no),

        // Timing
        .clk_16_i(clk_16_i),
        .clk_cpu_o(clk_cpu_o),
        .ram_oe_no(ram_oe_no),
        .ram_we_no(ram_we_no),

        // CPU
        .cpu_res_ai(cpu_res_ai),
        .cpu_res_nao(cpu_res_nao),
        .cpu_ready_o(cpu_ready_o),
        .cpu_sync_i(cpu_sync_i),

        // Address Decoding
        .cpu_en_o(cpu_en_o),
        .ram_ce_no(ram_ce_no),
        .pia1_cs2_no(pia1_cs2_no),
        .pia2_cs2_no(pia2_cs2_no),
        .via_cs2_no(via_cs2_no),
        .io_oe_no(io_oe_no),

        // Video
        .gfx_i(gfx_i),
        .h_sync_o(h_sync_o),
        .v_sync_o(v_sync_o),
        .video_o(video_o)
    );

    task reset;
        @(negedge clk_16_i);
        cpu_res_ai = 1'b1;
        #1 cpu_res_ai = '0;
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;
        $display("[%t] Test Begin", $time);

        reset();

        driver.read_at(17'h0e880);

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule