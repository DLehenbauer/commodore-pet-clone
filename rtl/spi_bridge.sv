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

module pi_com(
    input sys_clk,

    input spi_sclk,
    input spi_cs_n,
    input spi_rx,
    output spi_tx,

    output reg [16:0] pi_addr,
    input [7:0] pi_data_in,
    output reg [7:0] pi_data_out,
    output reg pi_rw_b = 1'b1,
    input pi_pending_in,                    // pi_pending_in also serves as a reset
    output reg pi_pending_out = 1'b0,
    input pi_done_in,
    output reg pi_done_out = 1'b0,
    
    output reg [2:0] state = READ_CMD,  // Expose internal state for debugging
    output [2:0] rx_count
);
    wire reset = !pi_pending_in;
    
    wire [7:0] rx [4];

    spi_buffer spi_buffer(
        .reset(reset),
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx(rx),
        .rx_count(rx_count),
        .tx_byte(pi_data_in)
    );

    wire cmd_a16        = rx[0][0];
    wire cmd_rw_b       = rx[0][1];
    wire cmd_set_addr   = rx[0][2];
    wire [2:0] cmd_len  = rx[0][7:5];

    localparam READ_CMD     = 3'd0,
               READ_ARGS    = 3'd1,
               XFER         = 3'd2,
               DONE         = 3'd3;

    always @(posedge sys_clk or posedge reset) begin
        if (reset) state <= READ_CMD;
        else state <= next_state;
    end

    reg [2:0] next_state = READ_CMD;
    reg [16:0] next_addr;

    always @(*) begin
        next_state = 3'bxxx;

        case (state)
            READ_CMD: begin
                pi_pending_out = 1'b0;
                pi_done_out = 1'b0;

                next_state = rx_count == 1'd1
                    ? READ_ARGS
                    : READ_CMD;
            end

            READ_ARGS: begin
                next_addr = cmd_len == 3'd1
                    ? pi_addr + 1'b1
                    : { cmd_a16, rx[1], rx[2] };
                
                next_state = rx_count == cmd_len
                    ? XFER
                    : READ_ARGS;
            end

            XFER: begin
                pi_rw_b = cmd_rw_b;
                pi_addr = next_addr;
                pi_data_out = rx[3];
                pi_pending_out = 1'b1;

                next_state = pi_done_in
                    ? DONE
                    : XFER;
            end

            DONE: begin
                pi_done_out = 1'b1;
                next_state = DONE;
            end
        endcase
    end
endmodule
