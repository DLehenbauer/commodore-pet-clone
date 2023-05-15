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

module pwm(
    input logic reset_i,
    input logic clk_i,
    input logic [15:0] compare_i,
    output logic out_o
);
    logic [16:0] accumulator = '0;
    
    always_ff @(posedge clk_i) begin
        if (reset_i) accumulator <= '0;
        else accumulator <= accumulator[15:0] + compare_i;
    end

    assign out_o = accumulator[16];
endmodule

module second_order_dac(
  input wire i_clk,
  input wire i_res,
  input wire i_ce,
  input wire [15:0] i_func, 
  output wire o_DAC
);

  reg this_bit;
 
  reg [19:0] DAC_acc_1st;
  reg [19:0] DAC_acc_2nd;
  reg [19:0] i_func_extended;
   
  assign o_DAC = this_bit;

  always @(*)
     i_func_extended = {i_func[15],i_func[15],i_func[15],i_func[15],i_func};
    
  always @(posedge i_clk or negedge i_res)
    begin
      if (i_res==0)
        begin
          DAC_acc_1st<=16'd0;
          DAC_acc_2nd<=16'd0;
          this_bit = 1'b0;
        end
      else if(i_ce == 1'b1) 
        begin
          if(this_bit == 1'b1)
            begin
              DAC_acc_1st = DAC_acc_1st + i_func_extended - (2**15);
              DAC_acc_2nd = DAC_acc_2nd + DAC_acc_1st     - (2**15);
            end
          else
            begin
              DAC_acc_1st = DAC_acc_1st + i_func_extended + (2**15);
              DAC_acc_2nd = DAC_acc_2nd + DAC_acc_1st + (2**15);
            end
          // When the high bit is set (a negative value) we need to output a 0 and when it is clear we need to output a 1.
          this_bit = ~DAC_acc_2nd[19];
        end
    end
endmodule

module audio(
    input  logic       reset_i,
    input  logic       clk8_i,
    input  logic       cpu_en_i,
    input  logic       sid_en_i,
    input  logic       cpu_wr_en_i,
    input  logic [4:0] addr_i,
    input  logic [7:0] data_i,      // writing to SID
    output logic [7:0] data_o,      // reading from SID

    input  logic       diag_i,
    input  logic       via_cb2_i,
    output logic       audio_o
);
    assign sid_wr_en = cpu_wr_en_i && sid_en_i;

    // See http://www.cbmhardware.de/show.php?r=14&id=71/PETSID
    logic signed [15:0] sid_out;

    sid#(.POT_SUPPORT(0)) sid(
        .clk(clk8_i),       // System clock
        .clkEn(cpu_en_i),   // 1 MHz clock enable
        .iRst(reset_i),     // sync. reset (active high)
        .iWE(sid_wr_en),    // write enable (active high)
        .iAddr(addr_i),     // sid address
        .iDataW(data_i),    // writing to SID
        .oDataR(data_o),    // reading from SID
        .oOut(sid_out)      // sid output
    );

    logic [15:0] waveOut = 0;

    always @(posedge clk8_i) begin
        waveOut <= sid_out + 16'h8000;
    end

    pwm pwm(
        .reset_i(reset_i),
        .clk_i(clk8_i),
        .compare_i(waveOut),
        .out_o(audio_o)
    );

    // second_order_dac dac(
    //     .i_clk(clk8_i),
    //     .i_res(!reset_i),
    //     .i_ce(1'b1),
    //     .i_func(waveOut), 
    //     .o_DAC(audio_o)
    // );

    // assign audio_o = via_cb2_i && diag_i;
endmodule
