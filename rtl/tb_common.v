task assert_equal(
    input integer actual,
    input integer expected,
    input string name
);
    if (actual !== expected) begin
        $display("[%t] '%s' must be %d, but got %d.", $time, name, expected, actual);
        $stop;
    end
endtask
