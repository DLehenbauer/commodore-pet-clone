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

module top_driver #(
    parameter SPI1_MHZ = 4
);
    logic         clk16_i = '0;
    logic         bus_rw_ni;
    logic         bus_rw_no;
    logic         bus_rw_noe;
    logic [15:0]  bus_addr_i;
    logic [16:0]  bus_addr_o;
    logic [15:0]  bus_addr_15_0_oe;
    logic  [7:0]  bus_data_i;
    logic  [7:0]  bus_data_o;
    logic  [7:0]  bus_data_7_0_oe;
    logic [11:10] ram_addr_o;
    
    logic         spi1_sck;
    logic         spi1_cs_n;
    logic         spi1_mcu_tx;
    logic         spi1_mcu_rx;
    logic         spi1_mcu_rx_oe;
    logic         spi_ready_no;

    logic         cpu_clk_o;
    logic         ram_oe_no;
    logic         ram_we_no;
    logic         cpu_res_ni;
    logic         cpu_res_no;
    logic         cpu_res_noe;
    logic         cpu_ready_o;
    logic         cpu_irq_ni;
    logic         cpu_irq_no;
    logic         cpu_irq_noe;
    logic         cpu_nmi_ni;
    logic         cpu_nmi_no;
    logic         cpu_nmi_noe;
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

    initial forever #(1000 / (16 * 2)) clk16_i = ~clk16_i;

    top top(
        .clk16_i(clk16_i),
        .bus_rw_ni(bus_rw_ni),
        .bus_rw_no(bus_rw_no),
        .bus_rw_noe(bus_rw_noe),
        .bus_addr_15_0_i(bus_addr_i),
        .bus_addr_15_0_o(bus_addr_o[15:0]),
        .bus_addr_15_0_oe(bus_addr_15_0_oe),
        .bus_addr_16_o(bus_addr_o[16]),
        .bus_data_7_0_i(bus_data_i),
        .bus_data_7_0_o(bus_data_o),
        .bus_data_7_0_oe(bus_data_7_0_oe),
        .ram_addr_o(ram_addr_o),
        
        // SPI1
        .spi1_sck_i(spi1_sck),
        .spi1_cs_ni(spi1_cs_n),
        .spi1_mcu_tx_i(spi1_mcu_tx),
        .spi1_mcu_rx_o(spi1_mcu_rx),
        .spi1_mcu_rx_oe(spi1_mcu_rx_oe),
        .spi_ready_no(spi_ready_no),

        .cpu_clk_o(cpu_clk_o),
        .ram_oe_no(ram_oe_no),
        .ram_we_no(ram_we_no),
        .cpu_res_ni(cpu_res_ni),
        .cpu_res_no(cpu_res_no),
        .cpu_res_noe(cpu_res_noe),
        .cpu_ready_o(cpu_ready_o),
        .cpu_irq_ni(cpu_irq_ni),
        .cpu_irq_no(cpu_irq_no),
        .cpu_irq_noe(cpu_irq_noe),
        .cpu_nmi_ni(cpu_nmi_ni),
        .cpu_nmi_no(cpu_nmi_no),
        .cpu_nmi_noe(cpu_nmi_noe),
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

    // The tri-state 'bus_addr' is internally controlled by a single '_oe' signal, but exposed from
    // the top level module as a vector of '_oe[15:0]' as required by Efinity.  For simplicity, we'll
    // use a single '_oe' signal for testing.
    wire bus_addr_oe = bus_addr_15_0_oe[0];

    // Paranoid check that all 'bus_addr_15_0_oe[15:0]' are in fact controlled by a single '_oe' signal.
    generate
        for (genvar i = 0; i < 16; i++) begin
            always begin
                #1 assert (bus_addr_15_0_oe[i] == bus_addr_oe)
                else begin
                    $error("Expected bus_addr_15_0_oe[15:0] == bus_addr_oe (bus_addr_15_0_oe[%d]=%d,bus_addr_oe=%d)", i, bus_addr_15_0_oe[i], bus_addr_oe);
                    $finish;
                end
            end
        end
    endgenerate

    // The tri-state 'bus_data' is internally controlled by a single '_oe' signal, but exposed from
    // the top level module as a vector of '_oe[15:0]' as required by Efinity.  For simplicity, we'll
    // use a single '_oe' signal for testing.
    wire bus_data_oe = bus_data_7_0_oe[0];

    // Paranoid check that all 'bus_data_7_0_oe[7:0]' are in fact controlled by a single '_oe' signal.
    generate
        for (genvar i = 0; i < 8; i++) begin
            always begin
                #1 assert (bus_data_7_0_oe[i] == bus_data_oe)
                else begin
                    $error("Expected bus_data_7_0_oe[7:0] == bus_data_oe (bus_data_7_0_oe[%d]=%d,bus_data_oe=%d)", i, bus_data_7_0_oe[i], bus_data_oe);
                    $finish;
                end
            end
        end
    endgenerate

    logic         cpu_rw_no;
    logic         cpu_rw_noe;
    logic [15:0]  cpu_addr_o;
    logic         cpu_addr_oe;
    logic  [7:0]  cpu_data_o;
    logic         cpu_data_oe;

    mock_cpu cpu(
        .cpu_rw_no(cpu_rw_no),
        .cpu_rw_noe(cpu_rw_noe),
        .cpu_addr_o(cpu_addr_o),
        .cpu_addr_oe(cpu_addr_oe),
        .cpu_data_o(cpu_data_o),
        .cpu_data_oe(cpu_data_oe),
        .cpu_be_i(cpu_be_o)
    );

    // The FPGA and CPU should never attempt to drive the bus signals simultaneously.
    always begin
        #1;
        
        assert((!bus_rw_noe) || (!cpu_rw_noe)) else begin
            $error("FPGA and CPU must not both drive 'bus_rw_n' simultaneously.");
            $finish;
        end

        assert((!bus_addr_15_0_oe) || (!cpu_addr_oe)) else begin
            $error("FPGA and CPU must not both drive 'bus_addr' simultaneously.");
            $finish;
        end

        assert((!bus_data_7_0_oe) || (!cpu_data_oe)) else begin
            $error("FPGA and CPU must not both drive 'bus_data' simultaneously.");
            $finish;
        end
    end

    mock_mcu #(SPI1_MHZ) mcu(
        .spi1_sck_o(spi1_sck),
        .spi1_cs_no(spi1_cs_n),
        .spi1_tx_o(spi1_mcu_tx),
        .spi1_rx_i(spi1_mcu_rx),
        .spi_ready_ni(spi_ready_ni)
    );

    always begin
        #1;
        
        assert(spi1_mcu_rx_oe != spi1_cs_n) else begin
            $error("FPGA must only drive MCU's RX pin when /CS is asserted.");
            $finish;
        end
    end

    task reset;
        mcu.reset();
    endtask
endmodule
