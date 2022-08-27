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
    reg pending = 0;
    reg clk = 0;
    wire strobe;
    wire done;

    sync sync(
        .clk(clk),
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

        $display("[%t] Test: 'pending' after positive colck edge does not raise strobe", $time);
        @(posedge clk);
        #1 pending = 1'b1;
        check(/* strobe: */ 0, /* done: */ 0);
        
        $display("[%t] Test: 'strobe' raised on next positive clock", $time);
        @(posedge clk);
        #1 check(/* strobe: */ 1, /* done: */ 0);
        
        $display("[%t] Test: 'done' raised on negative clock", $time);
        @(negedge clk);
        #1 check(/* strobe: */ 0, /* done: */ 1);
        
        $display("[%t] Test Complete", $time);
        $finish;
    end
endmodule