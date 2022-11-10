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
    input  logic sys_clk,

    input  logic spi_sclk,
    input  logic spi_cs_n,
    input  logic spi_rx,
    inout        spi_tx,

    output logic [16:0] pi_addr,
    input  logic [7:0] pi_data_in,
    output logic [7:0] pi_data_out,
    output logic pi_rw_b = 1'b1,
    input  logic pi_pending_in,                // pi_pending_in also serves as a reset
    output logic pi_pending_out = 1'b0,
    input  logic pi_done_in,
    output logic pi_done_out = 1'b0,
    
      // Expose internal state for debugging
    output logic [2:0] state = READ_CMD,
    output logic rx_valid
);
    wire reset = !pi_pending_in;
    logic [7:0] rx;
    
    spi_byte spi_byte(
        .sys_clk(sys_clk),
        .spi_sclk(spi_sclk),
        .spi_cs_n(!pi_pending_in),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx_byte(rx),
        .tx_byte(pi_data_in),
        .valid(rx_valid)
    );

    wire cmd_a16        = rx[0];
    wire [2:0] cmd_len  = rx[7:5];

    localparam READ_CMD          = 3'd0,
               READ_DATA_ARG     = 3'd1,
               READ_ADDR_HI_ARG  = 3'd2,
               READ_ADDR_LO_ARG  = 3'd3,
               XFER              = 3'd4,
               DONE              = 3'd5;

    always_ff @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            state           <= READ_CMD;
            pi_done_out     <= 1'b0;
            pi_pending_out  <= 1'b0;
        end else begin
            case (state)
                READ_CMD: begin
                    pi_done_out     <= 1'b0;
                    pi_pending_out  <= 1'b0;
                    pi_rw_b         <= 1'b1;

                    if (rx_valid) begin
                        if (cmd_len == 3'd1) begin
                            pi_addr <= pi_addr + 1'b1;
                            state   <= XFER;
                        end else begin
                            pi_addr <= { cmd_a16, 16'hxxxx };
                            state   <= cmd_len == 3'd3
                                ? READ_ADDR_HI_ARG
                                : READ_DATA_ARG;
                        end
                    end
                end

                READ_DATA_ARG: begin
                    pi_rw_b <= 1'b0;

                    if (rx_valid) begin
                        pi_data_out <= rx;
                        state       <= READ_ADDR_HI_ARG;
                    end
                end

                READ_ADDR_HI_ARG: begin
                    if (rx_valid) begin
                        pi_addr <= { pi_addr[16], rx, 8'hxx };
                        state   <= READ_ADDR_LO_ARG;
                    end
                end

                READ_ADDR_LO_ARG: begin
                    if (rx_valid) begin
                        pi_addr <= { pi_addr[16:8], rx };
                        state   <= XFER;
                    end
                end

                XFER: begin
                    pi_pending_out <= 1'b1;

                    if (pi_done_in) begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    pi_pending_out  <= 1'b0;
                    pi_done_out     <= 1'b1;
                end
            endcase
        end
    end
endmodule
