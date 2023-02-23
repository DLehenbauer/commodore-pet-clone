module sim;
    logic         clk_16_i;
    logic         bus_rw_ni;
    logic         bus_rw_no;
    logic         bus_rw_noe;
    logic [15:0]  bus_addr_i;
    logic [16:0]  bus_addr_o;
    logic [15:0]  bus_addr_oe;
    logic  [7:0]  bus_data_i;
    logic  [7:0]  bus_data_o;
    logic  [7:0]  bus_data_oe;
    logic [11:10] ram_addr_o;
    logic         spi1_sclk_i;
    logic         spi1_cs_ni;
    logic         spi1_rx_i;
    logic         spi1_tx_i;
    logic         spi1_tx_o;
    logic         spi1_tx_oe;
    logic         spi_ready_no;
    logic         clk_cpu_o;
    logic         ram_oe_no;
    logic         ram_we_no;
    logic         cpu_res_nai;
    logic         cpu_res_nao;
    logic         cpu_res_naoe;
    logic         cpu_ready_o;
    logic         cpu_irq_ni;
    logic         cpu_irq_no;
    logic         cpu_irq_noe;
    logic         cpu_nmi_ni;
    logic         cpu_nmi_no;
    logic         cpu_nmi_noe;
    logic         cpu_sync_i;
    logic         cpu_be_o;
    logic         ram_ce_no;
    logic         pia1_cs2_no;
    logic         pia2_cs2_no;
    logic         via_cs2_no;
    logic         io_oe_no;
    logic         diag_i;
    logic         cb2_i;
    logic         audio_o;
    logic         gfx_i;
    logic         h_sync_o;
    logic         v_sync_o;
    logic         video_o;
    logic         status_no;

    initial begin
        clk_16_i = 0;
        forever begin
            #31.25 clk_16_i = ~clk_16_i;
        end
    end

    top top(
        .clk_16_i(clk_16_i),
        .bus_rw_ni(bus_rw_ni),
        .bus_rw_no(bus_rw_no),
        .bus_rw_noe(bus_rw_noe),
        .bus_addr_i(bus_addr_i),
        .bus_addr_o(bus_addr_o[15:0]),
        .bus_addr16_o(bus_addr_o[16]),
        .bus_addr_oe(bus_addr_oe),
        .bus_data_i(bus_data_i),
        .bus_data_o(bus_data_o),
        .bus_data_oe(bus_data_oe),
        .ram_addr_o(ram_addr_o),
        .spi1_sclk_i(spi1_sclk_i),
        .spi1_cs_ni(spi1_cs_ni),
        .spi1_rx_i(spi1_rx_i),
        .spi1_tx_i(spi1_tx_i),
        .spi1_tx_o(spi1_tx_o),
        .spi1_tx_oe(spi1_tx_oe),
        .spi_ready_no(spi_ready_no),
        .clk_cpu_o(clk_cpu_o),
        .ram_oe_no(ram_oe_no),
        .ram_we_no(ram_we_no),
        .cpu_res_nai(cpu_res_nai),
        .cpu_res_nao(cpu_res_nao),
        .cpu_res_naoe(cpu_res_naoe),
        .cpu_ready_o(cpu_ready_o),
        .cpu_irq_ni(cpu_irq_ni),
        .cpu_irq_no(cpu_irq_no),
        .cpu_irq_noe(cpu_irq_noe),
        .cpu_nmi_ni(cpu_nmi_ni),
        .cpu_nmi_no(cpu_nmi_no),
        .cpu_nmi_noe(cpu_nmi_noe),
        .cpu_sync_i(cpu_sync_i),
        .cpu_be_o(cpu_be_o),
        .ram_ce_no(ram_ce_no),
        .pia1_cs2_no(pia1_cs2_no),
        .pia2_cs2_no(pia2_cs2_no),
        .via_cs2_no(via_cs2_no),
        .io_oe_no(io_oe_no),
        .diag_i(diag_i),
        .cb2_i(cb2_i),
        .audio_o(audio_o),
        .gfx_i(gfx_i),
        .h_sync_o(h_sync_o),
        .v_sync_o(v_sync_o),
        .video_o(video_o),
        .status_no(status_no)
    );

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars;

        #1000;

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule
