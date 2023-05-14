module audio_driver(
    input  logic clk16_i,
    output logic audio_o
);
    logic strobe_clk;
    logic cpu_en;

    timing timing(
        .clk16_i(clk16_i),
        .strobe_clk_o(strobe_clk),
        .cpu_en_o(cpu_en)
    );

    logic      reset_i = 1'b0;
    logic        rw_ni = 1'b1;
    logic [4:0] addr_i = 5'd0;
    logic [7:0] data_i = 8'd0;

    audio audio(
        .reset_i(reset_i),
        .clk8_i(strobe_clk),
        .cpu_en_i(cpu_en),
        .rw_ni(rw_ni),
        .addr_i(addr_i),
        .data_i(data_i),
        .audio_o(audio_o)
    );

    task reset;
        @(negedge cpu_en);
        reset_i = 1'b1;

        @(posedge cpu_en);
        @(negedge cpu_en);
        reset_i = '0;
    endtask

    task write(
        input logic [5:0] addr,
        input logic [7:0] value
    );
        integer i;

        @(negedge cpu_en);
        addr_i = addr;
        data_i = value;
        rw_ni  = 1'b0;

        @(posedge cpu_en);
        @(negedge cpu_en);
        rw_ni  = 1'b1;
    endtask

    task master_vol(
        input [3:0] volume
    );
        write(8'd24, { 4'h1, volume });
    endtask

    task voice1_freq(
        input [15:0] freq
    );
        write(8'd0, freq[7:0]);
        write(8'd1, freq[15:8]);
    endtask

    task voice1_adsr(
        input logic [3:0] att,
        input logic [3:0] dec,
        input logic [3:0] sus,
        input logic [3:0] rel
    );
        write(8'd5, { att, dec });
        write(8'd6, { sus, rel });
    endtask

    task voice1_on();
        write(8'd4, 8'b0001_0001);
    endtask
endmodule
