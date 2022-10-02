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
    
    output reg [2:0] state = IDLE           // Expose internal state for debugging
);
    wire [7:0] rx [4];
    reg  [2:0] length;
    wire buffer_valid_1;

    spi_buffer spi_buffer(
        .reset(!pi_pending_in),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .length(length),
        .rx(rx),
        .tx_byte(pi_data_in),
        .valid(buffer_valid_1)
    );

    reg buffer_valid_2 = 0;
    reg buffer_valid_3 = 0;

    always @(negedge sys_clk or negedge pi_pending_in) begin
        if (!pi_pending_in) begin
            buffer_valid_3 <= 0;
            buffer_valid_2 <= 0;
        end else begin
            buffer_valid_3 <= buffer_valid_2;
            buffer_valid_2 <= buffer_valid_1;
        end
    end

    wire buffer_valid = buffer_valid_2 & ~buffer_valid_3;

    wire cmd_a16        = rx[0][0];
    wire cmd_rw_b       = rx[0][1];
    wire cmd_set_addr   = rx[0][2];
    wire [2:0] cmd_len  = rx[0][7:5];

    localparam IDLE         = 3'd0,
               READ_CMD     = 3'd1,
               READ_ARGS    = 3'd2,
               XFER         = 3'd3,
               DONE         = 3'd4;

    always @(posedge sys_clk or negedge pi_pending_in) begin
        if (!pi_pending_in) begin
            state <= IDLE;
            pi_done_out <= 1'b0;
            pi_pending_out <= 1'b0;
        end else begin
            case (next_state)
                IDLE: begin
                    length <= 3'd0;
                    pi_done_out <= 1'b0;
                    pi_pending_out <= 1'b0;
                end

                READ_CMD: begin
                    length <= 3'd1;
                end

                READ_ARGS: begin
                    length <= cmd_len;
                end

                XFER: begin
                    pi_rw_b <= cmd_rw_b;
                    pi_addr <= cmd_set_addr
                        ? { cmd_a16, rx[1], rx[2] }
                        : next_addr;
                    pi_data_out <= rx[3];
                    pi_pending_out <= 1'b1;
                end

                DONE: begin
                    pi_done_out <= 1'b1;
                end
            endcase

            state <= next_state;
        end
    end

    reg [2:0] next_state = IDLE;

    reg [16:0] next_addr;
    
    wire done = state == DONE;
    always @(posedge done) begin
        next_addr <= pi_addr + 1'b1;
    end

    always @(*) begin
        next_state <= 3'bxxx;

        case (state)
            IDLE: begin
                if (pi_pending_in) next_state <= READ_CMD;
                else next_state <= IDLE;
            end

            READ_CMD: begin
                if (buffer_valid) begin
                    next_state <= cmd_len == 3'd1
                        ? XFER
                        : READ_ARGS;
                end else next_state <= READ_CMD;
            end

            READ_ARGS: begin
                if (buffer_valid) begin
                    next_state <= XFER;
                end else next_state <= READ_ARGS;
            end

            XFER: begin
                if (!pi_done_in) next_state <= XFER;
                else if (pi_done_in) next_state <= DONE;
            end

            DONE: begin
                next_state <= DONE;
            end
        endcase
    end
endmodule
