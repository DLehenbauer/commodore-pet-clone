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
    output logic spi_sck_o,
    output logic spi_cs_no,
    output logic spi_pico_o,
    input  logic spi_poci_i
);
    spi_driver #(CLK_MHZ, SCK_MHZ) spi(
        .spi_sck_o(spi_sck_o),
        .spi_cs_no(spi_cs_no),
        .spi_rx_i(spi_poci_i),
        .spi_tx_o(spi_pico_o)
    );

    task reset;
        $display("[%t]    spi1.reset()", $time);
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

    task write_at(
        input [16:0] addr_i,
        input [7:0] data_i
    );
        logic [7:0] c;
        logic [7:0] ah;
        logic [7:0] al;

        $display("[%t]    spi1.write_at(%x, %x)", $time, addr_i, data_i);

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

        $display("[%t]    spi1.read_at(%x, %x)", $time, addr_i);

        c = cmd(/* rw_n: */ 1'b1, /* set_addr: */ 1'b1, addr_i);
        ah = addr_hi(addr_i);
        al = addr_lo(addr_i);

        spi.send('{ c, ah, al });
    endtask

    task read_next();
        logic [7:0] c;

        $display("[%t]    spi1.read_next()", $time);

        c = cmd(/* rw_n: */ 1'b1, /* set_addr: */ 1'b0, 6'bxxxxxx);

        spi.send('{ c });
    endtask

    task set_cpu(
        input reset,
        input ready
    );
        write_at(17'he80f, { 6'h00, ready, !reset });
    endtask
endmodule
