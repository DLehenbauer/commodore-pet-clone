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
    input pi_pending_in,                // pi_pending_in also serves as a reset
    output reg pi_pending_out = 1'b0,
    input pi_done_in,
    output reg pi_done_out = 1'b0,
    
    output reg [2:0] state = READ_CMD   // Expose internal state for debugging
);
    wire reset = !pi_pending_in;
    logic rx_valid;
    logic [7:0] rx;
    
    spi_byte spi_byte(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx(rx),
        .tx(pi_data_in),
        .valid(rx_valid)
    );

    wire cmd_a16        = rx[0];
    wire cmd_rw_b       = rx[1];
    wire cmd_set_addr   = rx[2];
    wire [2:0] cmd_len  = rx[7:5];

    localparam READ_CMD          = 4'd0,
               READ_DATA_ARG     = 4'd1,
               READ_ADDR_HI_ARG  = 4'd2,
               READ_ADDR_LO_ARG  = 4'd3,
               XFER              = 4'd4,
               DONE              = 4'd5;

    always_ff @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            state       <= READ_CMD;
            pi_addr     <= next_addr;
            pi_data_out <= next_data;
            pi_rw_b     <= next_rw_b;
        end else begin
            state       <= next_state;
            pi_addr     <= next_addr;
            pi_data_out <= next_data;
            pi_rw_b     <= next_rw_b;
        end
    end

    logic [3:0] next_state = READ_CMD;
    logic [16:0] next_addr;
    logic [7:0] next_data;
    logic next_rw_b;

    always_comb begin
        pi_done_out     = 1'b0;
        pi_pending_out  = 1'b0;
        next_state      = 4'bxxxx;
        
        next_addr       = pi_addr;
        next_data       = pi_data_out;
        next_rw_b       = pi_rw_b;
        
        case (state)
            READ_CMD: begin
                next_rw_b   = 1'b1;

                if (!rx_valid) next_state = READ_CMD;
                else begin
                    if (cmd_len == 3'd1) begin
                        next_addr   = pi_addr + 1'b1;
                        next_state  = XFER;
                    end else begin
                        next_addr = { cmd_a16, 16'hxxxx };
                        next_state = cmd_len == 3'd3
                            ? READ_ADDR_HI_ARG
                            : READ_DATA_ARG;
                    end
                end
            end

            READ_DATA_ARG: begin
                next_rw_b  = 1'b0;

                if (!rx_valid) begin
                    next_state = READ_DATA_ARG;
                end else begin
                    next_data  = rx;
                    next_state = READ_ADDR_HI_ARG;
                end
            end

            READ_ADDR_HI_ARG: begin
                if (!rx_valid) begin
                    next_state = READ_ADDR_HI_ARG;
                end else begin
                    next_addr = { pi_addr[16], rx, 8'hxx };
                    next_state = READ_ADDR_LO_ARG;
                end
            end

            READ_ADDR_LO_ARG: begin
                if (!rx_valid) begin
                    next_state = READ_ADDR_LO_ARG;
                end else begin
                    next_addr = { pi_addr[16:8], rx };
                    next_state = XFER;
                end
            end

            XFER: begin
                if (!pi_done_in) begin
                    pi_pending_out = 1'b1;
                    next_state = XFER;
                end else begin
                    next_state = DONE;
                end
            end

            DONE: begin
                pi_done_out = 1'b1;
                next_state = DONE;
            end
        endcase
    end
endmodule
