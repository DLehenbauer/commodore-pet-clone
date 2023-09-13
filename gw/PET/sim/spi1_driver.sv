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
    parameter SCK_MHZ = 24
)(
    input  logic        clk_i,

    output logic        spi_valid_o,    // Next SPI command received: '_addr_o', '_data_o', and '_rw_no' are valid.
    output logic [16:0] spi_addr_o,     // Bus address of pending read/write command
    input  logic  [7:0] spi_data_i,     // Data returned from completed read command
    output logic  [7:0] spi_data_o,     // Data to be written by pending write command
    output logic        spi_rw_no,      // Direction of pending command (0 = write, 1 = read)
    
    input  logic        spi_ready_ni
);
    logic sck;
    logic cs_n;
    logic pico;
    logic poci;

    spi_driver #(SCK_MHZ) spi(
        .spi_sck_o(sck),
        .spi_cs_no(cs_n),
        .spi_rx_i(poci),
        .spi_tx_o(pico)
    );

    spi1 spi1(
        .spi_sck_i(sck),
        .spi_cs_ni(cs_n),
        .spi_rx_i(pico),
        .spi_tx_o(poci),

        .clk_i(clk_i),
        .spi_valid_o(spi_valid_o),
        .spi_addr_o(spi_addr_o),
        .spi_data_i(spi_data_i),
        .spi_data_o(spi_data_o),
        .spi_rw_no(spi_rw_no)
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

    logic [16:0] expected_addr;
    logic        expected_rw_n;
    logic [7:0]  expected_data;

    task check();
        wait (spi_valid_o);
        @(posedge clk_i);

        assert(spi_addr_o == expected_addr) else begin
            $error("'spi_addr_o' must produce expected address.  (expected=%h, actual=%h)", expected_addr, spi_addr_o);
            $finish;
        end

        assert(spi_rw_no == expected_rw_n) else begin
            $error("'spi_rw_no' must produce expected rw_n on positive edge of 'spi_valid_o'.  (expected=%h, actual=%h)", expected_rw_n, spi_rw_no);
            $finish;
        end

        assert(spi_rw_no || spi_data_o == expected_data) else begin
            $error("'spi_data_o' must produce expected data when writing.  (expected=%h, actual=%h)", expected_data, spi_data_o);
            $finish;
        end
    endtask

    task write_at(
        input [16:0] addr_i,
        input [7:0] data_i
    );
        logic [7:0] c;
        logic [7:0] ah;
        logic [7:0] al;

        expected_addr   = addr_i;
        expected_data   = data_i;
        expected_rw_n   = '0;

        c = cmd(/* rw_n: */ '0, /* set_addr: */ 1'b1, addr_i);
        ah = addr_hi(addr_i);
        al = addr_lo(addr_i);

        spi.send('{ c, data_i, ah, al });

        check();
    endtask

    task read_at(
        input [16:0] addr_i
    );
        logic [7:0] c;
        logic [7:0] ah;
        logic [7:0] al;

        expected_addr   = addr_i;
        expected_data   = 8'hxx;
        expected_rw_n   = 1'b1;

        c = cmd(/* rw_n: */ 1'b1, /* set_addr: */ 1'b1, addr_i);
        ah = addr_hi(addr_i);
        al = addr_lo(addr_i);

        spi.send('{ c, ah, al });

        check();
    endtask

    task read_next();
        spi.send('{ /* rw_n: */ 1'b1, /* set_addr: */ 1'b0, 6'bxxxxxx });

        //check(/* pending: */ 1'b1, /* rw_b: */ '0, addr_i, data_i);
    endtask

    task set_cpu(
        input reset,
        input ready
    );
        write_at(17'he80f, { 6'h00, ready, !reset });
    endtask

    always @(negedge cs_n) begin
        assert(spi_ready_ni) else begin
            $error("'spi_ready_n' must be deasserted on positive edge 'spi1_cs_n'.  (spi_cs_n=%d, spi_ready_n=%d)", cs_n, spi_ready_ni);
            $finish;
        end
    end

    always @(posedge cs_n) begin
        #1 assert(spi_ready_ni) else begin
            $error("Deasserting 'spi1_cs_n' must reset 'spi_ready_n'.  (spi_cs_n=%d, spi_ready_n=%d)", cs_n, spi_ready_ni);
            $finish;
        end
    end
endmodule
