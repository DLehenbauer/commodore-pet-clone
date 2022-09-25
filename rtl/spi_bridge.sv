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
    output reg [7:0] pi_data_out,
    output reg pi_rw_b = 1'b1,
    input pi_pending_in,                    // pi_pending_in also serves as a reset
    output reg pi_pending_out = 1'b0,
    input pi_done_in,
    output reg pi_done_out = 1'b0
);
    wire [7:0] rx [4];
    reg  [2:0] length;
    wire buffer_valid_1;

    wire rw_b_in = rx[0][7];
    wire a16_in  = rx[0][6];
    wire [5:0] cmd_in  = rx[0][5:0];

    spi_buffer spi_buffer(
        .reset(!pi_pending_in),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .length(length),
        .rx(rx),
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

    localparam CMD_WRITE = 0;

    localparam IDLE         = 3'd0,
               READ_CMD     = 3'd1,
               WRITING      = 3'd2,
               COMPLETING   = 3'd3,
               DONE         = 3'd4;

    reg [2:0] state = IDLE;

    // The Pi Pico pulses CS_N after every byte which is convenient for advancing our state.
    // With another SPI controller, we would need to use a separate clock.
    wire state_clk = spi_cs_n | spi_sclk;

    // SPI MODE0 reads/writes on the positive clock edge.  We transition the state machine
    // on the negative clock edge.
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

                WRITING: begin
                    length <= 3'd4;
                end

                COMPLETING: begin
                    pi_rw_b         <= rw_b_in;
                    pi_addr         <= { a16_in, rx[1], rx[2] };
                    pi_data_out     <= rx[3];
                    pi_pending_out  <= 1'b1;
                end

                DONE: begin
                    pi_done_out = 1'b1;
                end
            endcase

            state <= next_state;
        end
    end

    reg [2:0] next_state = IDLE;

    always @(*) begin
        next_state <= 3'bxxx;

        case (state)
            IDLE: begin
                if (pi_pending_in) next_state <= READ_CMD;
                else next_state <= IDLE;
            end

            READ_CMD: begin
                if (buffer_valid) begin
                    case (cmd_in)
                        CMD_WRITE: next_state <= WRITING;
                    endcase
                end else next_state <= READ_CMD;
            end

            WRITING: begin
                if (buffer_valid) begin next_state <= COMPLETING;
                end else next_state <= WRITING;
            end

            COMPLETING: begin
                if (!pi_done_in) next_state <= COMPLETING;
                else if (pi_done_in) next_state <= DONE;
            end

            DONE: next_state <= DONE;
        endcase
    end
endmodule
