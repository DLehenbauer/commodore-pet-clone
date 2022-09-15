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

module spi_byte (
    input  spi_sclk,
    input  spi_cs_n,        // SPI chip select also doubles as an asyncronous reset
    input  spi_rx,
    output spi_tx,

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Producer must latch while transmitting.

    output reg done = 1
);
    always @(posedge spi_sclk) begin
        if (!spi_cs_n) begin
            rx <= { rx[6:0], spi_rx };
        end
    end

    reg [2:0] tx_bit_index = 3'd7;

    always @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            tx_bit_index <= 7;
            done <= 0;
        end else begin
            tx_bit_index <= tx_bit_index - 1'b1;
            done <= tx_bit_index == 3'd0;
        end
    end

    assign spi_tx = tx[tx_bit_index];
endmodule

module spi_buffer(
    input spi_sclk,
    input spi_cs_n,
    input spi_rx,
    output spi_tx,

    output reg [7:0] rx [4],
    input      [7:0] tx [4],
    input      [2:0] length,

    output done
);
    reg [2:0] count = 0;
    wire [7:0] rx_byte;
    wire [7:0] tx_byte = tx[count];
    wire byte_done;

    spi_byte spi(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx(rx_byte),
        .tx(tx_byte),
        .done(byte_done)
    );

    always @(posedge byte_done or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            count <= 1'b0;
        end else begin
            rx[count] <= rx_byte;
            count <= count + 1'b1;
        end
    end

    assign done = !spi_cs_n && count == length;
endmodule

module pi_com(
    input reset,
    input spi_sclk_src,
    output spi_sclk,
    output reg spi_cs_n,
    input spi_rx,
    output spi_tx,

    output reg [16:0] pi_addr,
    output reg [7:0] pi_data_out,
    output reg pi_rw_b = 1'b1,
    input pi_pending_in,
    output reg pi_pending_out = 1'b0,
    input pi_done_in,
    output reg pi_done_out = 1'b0
);
    assign spi_sclk = spi_sclk_src & !spi_cs_n;

    wire [7:0] rx [4];
    reg  [2:0] length;
    wire done;

    wire rw_b_in = rx[0][7];
    wire a16_in  = rx[0][6];
    wire cmd_in  = rx[0][5:0];

    spi_buffer spi_buffer(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .length(length),
        .rx(rx),
        .done(done)
    );

    localparam CMD_WRITE = 0;

    localparam IDLE = 0,
               READ_CMD = 1,
               WRITING = 2,
               COMPLETING = 3,
               DONE = 4;

    reg [2:0] state = IDLE;

    // SPI MODE0 reads/writes on the positive clock edge.  We transition the state machine
    // on the negative clock edge.
    always @(negedge spi_sclk_src or posedge reset or negedge pi_pending_in) begin
        if (reset || !pi_pending_in) begin
            state <= IDLE;
            spi_cs_n <= 1'b1;
            pi_done_out <= 1'b0;
            pi_pending_out <= 1'b0;
        end else begin
            case (next_state)
                IDLE: begin
                    length <= 3'd0;
                    spi_cs_n <= 1'b1;
                    pi_done_out <= 1'b0;
                    pi_pending_out <= 1'b0;
                end

                READ_CMD: begin
                    length <= 3'd1;
                    spi_cs_n <= 1'b0;
                end

                WRITING: begin
                    length <= 3'd4;
                end

                COMPLETING: begin
                    spi_cs_n <= 1'b1;
        
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
                if (done) begin
                    case (cmd_in)
                        CMD_WRITE: next_state <= WRITING;
                    endcase
                end else next_state <= READ_CMD;
            end

            WRITING: begin
                if (done) begin next_state <= COMPLETING;
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
