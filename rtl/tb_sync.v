`timescale 1ns / 1ps

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

module tb();
    reg clk16 = 0;
    wire select;
    wire enable;
    reg pending = 0;
    wire strobe;
    wire done;

    bus bus(
        .clk16(clk16),
        .pi_select(select),
        .pi_strobe(enable)
    );

    sync sync(
        .select(select),
        .enable(enable),
        .pending(pending),
        .strobe(strobe),
        .done(done)
    );

    task check(
        input expected_strobe,
        input expected_done
    );
        assert_equal(strobe, expected_strobe, "strobe");
        assert_equal(done, expected_done, "done");
    endtask

    initial begin
        clk16 = 0;
        forever begin
            #62.5 clk16 = ~clk16;
        end
    end

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        $display("[%t] Test: 'strobe' and 'done' are initially 0", $time);
        check(/* strobe: */ 0, /* done: */ 0);

        $display("[%t] Test: No 'strobe' if 'pending' low.", $time);
        @(posedge select);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(posedge enable);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(negedge enable);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(negedge select);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        $display("[%t] Test: 'pending' after 'select' delayed until next 'select'", $time);
        @(posedge select);
        #1 pending = 1'b1;
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(posedge enable);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(negedge enable);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(negedge select);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(posedge select);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(posedge enable);
        #1 check(/* strobe: */ 1, /* done: */ 0);

        @(negedge enable);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(negedge select);
        #1 check(/* strobe: */ 0, /* done: */ 1);

        $display("[%t] Test: 'done' cleared on negative pending", $time);
        pending = 1'b0;
        #1 check(/* strobe: */ 0, /* done: */ 0);

        $display("[%t] Test: 'pending' before select raises 'strobe' on next enable", $time);
        #1 pending = 1'b1;

        @(posedge select);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(posedge enable);
        #1 check(/* strobe: */ 1, /* done: */ 0);

        @(negedge enable);
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(negedge select);
        #1 check(/* strobe: */ 0, /* done: */ 1);

        $display("[%t] Test: 'done' cleared on negative pending", $time);
        pending = 1'b0;
        #1 check(/* strobe: */ 0, /* done: */ 0);

        @(posedge select)
        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule