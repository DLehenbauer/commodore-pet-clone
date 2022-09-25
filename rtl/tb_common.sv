task assert_equal(
    input integer actual,
    input integer expected,
    input string name
);
    if (actual !== expected) begin
        $error("'%s' must be %0d ($%x), but got %0d ($%x).", name, expected, expected, actual, actual);
        $stop;
    end
endtask
