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
    reg enabled = 0;
    reg pending = 0;
    reg clk = 0;
    wire strobe;
    wire done;

    sync sync(
        .clk(clk),
        .enabled(enabled),
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
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end
    end

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;

        $display("[%t] Test: 'strobe' and 'done' are initially 0", $time);
        check(/* strobe: */ 0, /* done: */ 0);

        $display("[%t] Test: 'pending' without 'enabled' does not raise strobe", $time);
        @(posedge clk);
        #1 pending = 1'b1;
        check(/* strobe: */ 0, /* done: */ 0);

        @(posedge clk);
        #1 pending = 1'b1;
        check(/* strobe: */ 0, /* done: */ 0);

        // TODO: Current 'sync' raises strobe immediately on enabled, which is arguably correct
        //       since enabled only goes high on a positive clock edge.

        $display("[%t] Test: 'pending/enabled' does not raise strobe until next positive clock edge", $time);

        #1 enabled = 1'b1;
        check(/* strobe: */ 0, /* done: */ 0);

        $display("[%t] Test: 'pending/enabled' raises strobe on next positive clock edge", $time);

        @(posedge clk);
        #1 check(/* strobe: */ 1, /* done: */ 0);
        
        $display("[%t] Test: '!enabled' does not raise 'done'", $time);
        enabled = 1'b0;
        #1 check(/* strobe: */ 0, /* done: */ 0);

        $display("[%t] Test: 'done' raised on next positive clock edge", $time);
        @(posedge clk);
        #1 check(/* strobe: */ 0, /* done: */ 1);
        
        $display("[%t] Test: 'done' held while still pending", $time);
        @(posedge clk);
        #1 check(/* strobe: */ 0, /* done: */ 1);

        $display("[%t] Test: 'done' reset when !pending", $time);
        #1 pending = 1'b0;
        #1 check(/* strobe: */ 0, /* done: */ 0);

        $display("[%t] Test: pending/enabled high without clock edge", $time);
        #1 pending = 1'b1;
        #1 enabled = 1'b1;
        #1 check(/* strobe: */ 0, /* done: */ 0);

        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule