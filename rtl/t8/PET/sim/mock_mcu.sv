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

module mock_mcu #(
    parameter SPI1_MHZ = 4
)(
    output logic spi1_sck_o,
    output logic spi1_cs_no,
    output logic spi1_tx_o,
    input  logic spi1_rx_i,
    input  logic spi_ready_ni
);
    spi_driver #(SPI1_MHZ) spi1(
        .spi_sck_o(spi1_sck_o),
        .spi_cs_no(spi1_cs_no),
        .spi_tx_o(spi1_tx_o),
        .spi_rx_i(spi_rx_i)
    );

    task reset;
        spi1.reset();
    endtask

    task send(
        logic unsigned [7:0] tx[]
    );
        integer i;
        string s;

        s = $sformatf(" %%%b ", tx[0]);
        for (i = 1; i < tx.size(); i++) begin
            s = { s, $sformatf("%h ", tx[i]) };
        end

        $display("[%t]    send -> [%s]", $time, s);
        spi1.xfer_bytes(tx);

        // MCU continues asserting /CS until FPGA has finished processing the command,
        // indicated by the FPGA asserting READY.
        wait (spi_ready_ni == '0);

        spi1.end_xfer();
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

    logic [16:0] last_addr;

    task write_at(
        input [16:0] addr_i,
        input [7:0] data_i
    );
        logic [7:0] c;
        logic [7:0] ah;
        logic [7:0] al;

        c = cmd(/* rw_n: */ '0, /* set_addr: */ 1'b1, addr_i);
        ah = addr_hi(addr_i);
        al = addr_lo(addr_i);
        last_addr = addr_i;

        send('{ c, data_i, ah, al });

        //check(/* pending: */ 1'b1, /* rw_b: */ '0, addr_i, data_i);
    endtask

    task read_at(
        input [16:0] addr_i
    );
        logic [7:0] c;
        logic [7:0] ah;
        logic [7:0] al;
        last_addr = addr_i;

        c = cmd(/* rw_n: */ 1'b1, /* set_addr: */ 1'b1, addr_i);
        ah = addr_hi(addr_i);
        al = addr_lo(addr_i);

        send('{ c, ah, al });

        //check(/* pending: */ 1'b1, /* rw_b: */ 1'b1, addr_i, /* data: */ 8'hxx);
    endtask

    task set_cpu(
        input reset,
        input ready
    );
        write_at(17'he80f, { 6'h00, ready, !reset });
    endtask

    always @(negedge spi1_cs_no) begin
        assert(spi_ready_ni) else begin
            $error("'spi_ready_n' must be deasserted on positive edge 'spi1_cs_n'.  (spi_cs_n=%d, spi_ready_n=%d)", spi1_cs_no, spi_ready_ni);
            $finish;
        end
    end

    always @(posedge spi1_cs_no) begin
        #1 assert(spi_ready_ni) else begin
            $error("Deasserting 'spi1_cs_n' must reset 'spi_ready_n'.  (spi_cs_n=%d, spi_ready_n=%d)", spi1_cs_no, spi_ready_ni);
            $finish;
        end
    end
endmodule
