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
    input  logic        clk_i,

    output logic [16:0] addr_o,
    input  logic  [7:0] rd_data_i,
    output logic  [7:0] wr_data_o,
    output logic        we_o,
    output logic        cycle_o
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
    logic ack = '0;

    spi1_master spi1_master(
        .spi_sck_i(sck),
        .spi_cs_ni(cs_n),
        .spi_rx_i(pico),
        .spi_tx_o(poci),
        .spi_ready_o(spi_ready),

        .clk_i(clk_i),
        .addr_o(addr_o),
        .rd_data_i(rd_data_i),
        .wr_data_o(wr_data_o),
        .we_o(we_o),
        .cycle_o(cycle_o)
    );

    task reset;
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

    // We allow 
    logic        expected_rd_index = '0;
    logic        expected_wr_index = '0;
    logic [16:0] expected_addr_fifo [2];
    logic        expected_we_fifo   [2];
    logic [7:0]  expected_data_fifo [2];

    wire [16:0] expected_addr = expected_addr_fifo[expected_rd_index];
    wire        expected_we   = expected_we_fifo[expected_rd_index];
    wire [7:0]  expected_data = expected_data_fifo[expected_rd_index];

    wire [16:0] last_addr     = expected_addr_fifo[expected_wr_index - 1'b1];

    task set_expected(
        input [16:0] addr_i,
        input        we_i,
        input [7:0]  data_i = 8'hxx
    );
        expected_addr_fifo[expected_wr_index]  <= addr_i;
        expected_data_fifo[expected_wr_index]  <= data_i;
        expected_we_fifo[expected_wr_index]    <= we_i;

        expected_wr_index <= expected_wr_index + 1'b1;
    endtask

    task write_at(
        input [16:0] addr_i,
        input [7:0] data_i
    );
        logic [7:0] c;
        logic [7:0] ah;
        logic [7:0] al;

        $display("[%t]    spi1.write_at(%x, %x)", $time, addr_i, data_i);

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

        set_expected(/* addr: */ last_addr + 1'b1, /* we: */ '0);

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
        @(posedge clk_i)    // 2FF stage 1
        @(posedge clk_i)    // 2FF stage 2
        @(posedge clk_i)    // Edge detect
        #1 assert(!spi_ready) else begin
            $error("Asserting 'spi1_master_cs_n' must reset 'spi_ready'.  (spi_cs_n=%d, spi_ready=%d)", cs_n, spi_ready);
            $finish;
        end
    end

    always @(negedge cs_n) begin
        @(posedge clk_i)    // 2FF stage 1
        @(posedge clk_i)    // 2FF stage 2
        @(posedge clk_i)    // Edge detect
        #1 assert(!cycle_o) else begin
            $error("Deasserting 'spi1_master_cs_n' must reset 'cycle_o'.  (spi_cs_n=%d, cycle_o=%d)", cs_n, cycle_o);
            $finish;
        end
    end

    always @(posedge cycle_o) begin
        #1 assert(addr_o == expected_addr) else begin
            $error("'addr_o' must produce expected address.  (expected=%h, actual=%h)", expected_addr, addr_o);
            $finish;
        end

        assert(we_o == expected_we) else begin
            $error("'we_o' must produce expected rw_n.  (expected=%h, actual=%h)", expected_we, we_o);
            $finish;
        end

        assert(!we_o || wr_data_o == expected_data) else begin
            $error("'wr_data_o' must produce expected data when writing.  (expected=%h, actual=%h)", expected_data, wr_data_o);
            $finish;
        end

        expected_rd_index <= expected_rd_index + 1'b1;
    end
endmodule
