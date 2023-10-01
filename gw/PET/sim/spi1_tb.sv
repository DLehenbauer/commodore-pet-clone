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

module spi1_tb;
    bit clk = '0;
    initial forever #(1000 / (64 * 2)) clk = ~clk;

    logic spi_sck;
    logic spi_cs_n;
    logic spi_pico;
    logic spi_poci;

    spi1_driver spi1_driver(
        .clk_i(clk),
        .spi_sck_o(spi_sck),
        .spi_cs_no(spi_cs_n),
        .spi_pico_o(spi_pico),
        .spi_poci_i(spi_poci)
    );

    logic [16:0] addr;
    logic  [7:0] rd_data;
    logic  [7:0] wr_data;
    logic        we;
    logic        cycle;
    logic        spi_ready;
    logic        ack = '0;

    spi1_master spi1(
        .spi_sck_i(spi_sck),
        .spi_cs_ni(spi_cs_n),
        .spi_rx_i(spi_pico),
        .spi_tx_o(spi_poci),
        .spi_ready_o(spi_ready),

        .clk_i(clk),
        .addr_o(addr),
        .rd_data_i(rd_data),
        .wr_data_o(wr_data),
        .we_o(we),
        .cycle_o(cycle),
        .ack_i(ack)
    );

    logic [16:0] expected_addr;
    logic        expected_we;
    logic [7:0]  expected_data;

    task set_expected(
        input [16:0] addr_i,
        input        we_i,
        input [7:0]  data_i = 8'hxx
    );
        expected_addr <= addr_i;
        expected_data <= data_i;
        expected_we   <= we_i;
    endtask

    task write_at(
        input [16:0] addr_i,
        input [7:0] data_i
    );
        set_expected(/* addr: */ addr_i, /* we: */ 1'b1, /* data: */ data_i);
        spi1_driver.write_at(addr_i, data_i);
        @(posedge spi_ready);
    endtask

    task read_at(
        input [16:0] addr_i
    );
        set_expected(/* addr: */ addr_i, /* we: */ '0);
        spi1_driver.read_at(addr_i);
        @(posedge spi_ready);
    endtask

    task read_next();
        set_expected(/* addr: */ expected_addr + 1'b1, /* we: */ '0);
        spi1_driver.read_next();
        @(posedge spi_ready);
    endtask

    always @(negedge spi_cs_n) begin
        @(posedge clk)  // 2FF stage 1
        @(posedge clk)  // 2FF stage 2
        @(posedge clk)  // Edge detect
        
        #1;
        
        assert(!spi_ready) else begin
            $error("Asserting 'spi1_cs_n' must reset 'spi_ready'.  (spi_cs_n=%d, spi_ready=%d)", spi_cs_n, spi_ready);
            $finish;
        end

        assert(!cycle) else begin
            $error("Asserting 'spi1_cs_n' must reset 'cycle'.  (spi_cs_n=%d, cycle=%d)", spi_cs_n, cycle);
            $finish;
        end
    end

    always @(posedge cycle) begin
        $display("[%t]        (cycle=%b, addr=%x, we=%b, wr_data=%x, ack=%b, spi_ready=%b)", $time, cycle, addr, we, wr_data, ack, spi_ready);

        assert(addr == expected_addr) else begin
            $error("'addr' must produce expected address.  (expected=%h, actual=%h)", expected_addr, addr);
            $finish;
        end

        assert(we == expected_we) else begin
            $error("'we' must produce expected rw_n.  (expected=%h, actual=%h)", expected_we, we);
            $finish;
        end

        assert(!we || wr_data == expected_data) else begin
            $error("'wr_data' must produce expected data when writing.  (expected=%h, actual=%h)", expected_data, wr_data);
            $finish;
        end

        ack <= 1'b1;
        #1 $display("[%t]        (cycle=%b, ack=%b, spi_ready=%x)", $time, cycle, ack, spi_ready);
        @(posedge spi_ready);
        ack <= 1'b0;
        $display("[%t]        (cycle=%b, ack=%b, spi_ready=%x)", $time, cycle, ack, spi_ready);
    end

    initial begin
        $dumpfile("work_sim/out.vcd");
        $dumpvars(0, spi1_tb);

        spi1_driver.reset();

        write_at(17'h00000, 8'h00);
        read_next(8'h01);
        read_next(8'h01);
        read_next(8'h01);
        read_next(8'h01);
        read_next(8'h01);

        #100

        $display("[%t] Test Complete", $time);
        $finish;
    end
 endmodule
 