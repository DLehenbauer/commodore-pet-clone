task assert_equal(
    input integer actual,
    input integer expected,
    input string name
);
    if (actual !== expected) begin
        $error("FAIL: '%s' must be %d, but got %d.", name, expected, actual);
        $stop;
    end
endtask
