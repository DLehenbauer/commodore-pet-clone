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

module spi1_driver #(
    parameter CLK_MHZ = 64,         // Speed of destination clock
    parameter SCK_MHZ = 24          // SPI baud rate
) (
    input  logic        sba_clk_i,

    output logic [16:0] sba_addr_o,
    input  logic  [7:0] sba_rd_data_i,
    output logic  [7:0] sba_wr_data_o,
    output logic        sba_we_o,
    output logic        sba_cycle_o
);
    logic sck;
    logic cs_n;
    logic pico;
    logic poci;

    spi_driver #(CLK_MHZ, SCK_MHZ) spi(
        .spi_sck_o(sck),
        .spi_cs_no(cs_n),
        .spi_rx_i(poci),
        .spi_tx_o(pico)
    );

    logic spi_ready;
    logic sba_ack = '0;

    spi1_master spi1_master(
        .spi_sck_i(sck),
        .spi_cs_ni(cs_n),
        .spi_rx_i(pico),
        .spi_tx_o(poci),
        .spi_ready_o(spi_ready),

        .sba_clk_i(sba_clk_i),
        .sba_addr_o(sba_addr_o),
        .sba_rd_data_i(sba_rd_data_i),
        .sba_wr_data_o(sba_wr_data_o),
        .sba_we_o(sba_we_o),
        .sba_cycle_o(sba_cycle_o)
    );

    task reset;
        @(posedge sba_clk_i)
        @(posedge sba_clk_i)
        @(posedge sba_clk_i)
        @(posedge sba_clk_i)
        @(posedge sba_clk_i)
        spi.reset();
    endtask

    function [7:0] cmd(input bit rw_n, input bit set_addr, input logic [16:0] addr);
        return { rw_n, set_addr, 5'bxxxxx, addr[16] };
    endfunction

    function [7:0] addr_hi(input logic [16:0] addr);
        return addr[15:8];
    endfunction

    function [7:0] addr_lo(input logic [16:0] addr);
        return addr[7:0];
    endfunction

    logic [16:0] expected_addr [0:1];
    logic        expected_we   [0:1];
    logic [7:0]  expected_data [0:1];

    task set_expected(
        input [16:0] addr_i,
        input        we_i,
        input [7:0]  data_i = 8'hxx
    );
        expected_addr[0] <= addr_i;
        expected_data[0] <= data_i;
        expected_we[0] <= we_i;
    endtask

    task write_at(
        input [16:0] addr_i,
        input [7:0] data_i
    );
        logic [7:0] c;
        logic [7:0] ah;
        logic [7:0] al;

        set_expected(/* addr: */ addr_i, /* we: */ 1'b1, /* data: */ data_i);

        c = cmd(/* rw_n: */ '0, /* set_addr: */ 1'b1, addr_i);
        ah = addr_hi(addr_i);
        al = addr_lo(addr_i);

        spi.send('{ c, data_i, ah, al });
    endtask

    task read_at(
        input [16:0] addr_i
    );
        logic [7:0] c;
        logic [7:0] ah;
        logic [7:0] al;

        set_expected(/* addr: */ addr_i, /* we: */ '0);

        c = cmd(/* rw_n: */ 1'b1, /* set_addr: */ 1'b1, addr_i);
        ah = addr_hi(addr_i);
        al = addr_lo(addr_i);

        spi.send('{ c, ah, al });
    endtask

    task read_next();
        logic [7:0] c;

        set_expected(/* addr: */ expected_addr[1] + 1'b1, /* we: */ '0);

        c = cmd(/* rw_n: */ 1'b1, /* set_addr: */ 1'b0, 6'bxxxxxx);

        spi.send('{ c });
    endtask

    task set_cpu(
        input reset,
        input ready
    );
        write_at(17'he80f, { 6'h00, ready, !reset });
    endtask

    always @(negedge cs_n) begin
        @(posedge sba_clk_i)    // 2FF stage 1
        @(posedge sba_clk_i)    // 2FF stage 2
        @(posedge sba_clk_i)    // Edge detect
        #1 assert(!spi_ready) else begin
            $error("Asserting 'spi1_master_cs_n' must reset 'spi_ready'.  (spi_cs_n=%d, spi_ready=%d)", cs_n, spi_ready);
            $finish;
        end
    end

    always @(negedge cs_n) begin
        @(posedge sba_clk_i)    // 2FF stage 1
        @(posedge sba_clk_i)    // 2FF stage 2
        @(posedge sba_clk_i)    // Edge detect
        #1 assert(!sba_cycle_o) else begin
            $error("Deasserting 'spi1_master_cs_n' must reset 'sba_cycle_o'.  (spi_cs_n=%d, sba_cycle_o=%d)", cs_n, sba_cycle_o);
            $finish;
        end
    end

    always @(posedge sba_cycle_o) begin
        assert(sba_addr_o == expected_addr[1]) else begin
            $error("'sba_addr_o' must produce expected address.  (expected=%h, actual=%h)", expected_addr, sba_addr_o);
            $finish;
        end

        assert(sba_we_o == expected_we[1]) else begin
            $error("'sba_we_o' must produce expected rw_n on positive edge of 'spi_valid_o'.  (expected=%h, actual=%h)", expected_we, sba_we_o);
            $finish;
        end

        assert(!sba_we_o || sba_wr_data_o == expected_data[1]) else begin
            $error("'sba_wr_data_o' must produce expected data when writing.  (expected=%h, actual=%h)", expected_data, sba_wr_data_o);
            $finish;
        end

        expected_addr[1] <= expected_addr[0];
        expected_data[1] <= expected_data[0];
        expected_we[1] <= expected_we[0];
    end
endmodule
