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

module spi_bridge(
    input  logic clk_sys_i,

    input  logic spi_sclk_i,
    input  logic spi_cs_ni,      // Also serves as a synchronous reset for the FSM
    input  logic spi_rx_i,
    inout  wire  spi_tx_io,

    output logic [16:0] spi_addr_o,
    input  logic  [7:0] spi_data_i,
    output logic  [7:0] spi_data_o,
    output logic spi_rw_no = 1'b1,
    output logic spi_pending_o = 1'b0,
    input  logic spi_done_i,
    output logic spi_done_o = 1'b0,
    
    // Expose internal state for debugging
    output logic [2:0] state = READ_CMD,
    output logic rx_valid
);
    wire reset = spi_cs_ni;
    logic [7:0] rx;
    
    spi_byte spi_byte(
        .clk_sys_i(clk_sys_i),
        .spi_sclk_i(spi_sclk_i),
        .spi_cs_ni(spi_cs_ni),
        .spi_rx_i(spi_rx_i),
        .spi_tx_o(spi_tx_io),
        .rx_byte_o(rx),
        .tx_byte_i(spi_data_i),
        .valid_o(rx_valid)
    );

    wire       cmd_a16 = rx[0];
    wire [2:0] cmd_len = rx[7:5];

    localparam READ_CMD          = 3'd0,
               READ_DATA_ARG     = 3'd1,
               READ_ADDR_HI_ARG  = 3'd2,
               READ_ADDR_LO_ARG  = 3'd3,
               XFER              = 3'd4,
               DONE              = 3'd5;

    always_ff @(posedge clk_sys_i or posedge reset) begin
        if (reset) begin
            state          <= READ_CMD;
            spi_done_o     <= 1'b0;
            spi_pending_o  <= 1'b0;
        end else begin
            case (state)
                READ_CMD: begin
                    spi_done_o     <= 1'b0;
                    spi_pending_o  <= 1'b0;
                    spi_rw_no      <= 1'b1;

                    if (rx_valid) begin
                        if (cmd_len == 3'd1) begin
                            spi_addr_o <= spi_addr_o + 1'b1;
                            state   <= XFER;
                        end else begin
                            spi_addr_o <= { cmd_a16, 16'hxxxx };
                            state      <= cmd_len == 3'd3
                                ? READ_ADDR_HI_ARG
                                : READ_DATA_ARG;
                        end
                    end
                end

                READ_DATA_ARG: begin
                    spi_rw_no <= 1'b0;

                    if (rx_valid) begin
                        spi_data_o <= rx;
                        state      <= READ_ADDR_HI_ARG;
                    end
                end

                READ_ADDR_HI_ARG: begin
                    if (rx_valid) begin
                        spi_addr_o <= { spi_addr_o[16], rx, 8'hxx };
                        state      <= READ_ADDR_LO_ARG;
                    end
                end

                READ_ADDR_LO_ARG: begin
                    if (rx_valid) begin
                        spi_addr_o <= { spi_addr_o[16:8], rx };
                        state      <= XFER;
                    end
                end

                XFER: begin
                    spi_pending_o <= 1'b1;

                    if (spi_done_i) begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    spi_pending_o <= 1'b0;
                    spi_done_o    <= 1'b1;
                end
            endcase
        end
    end
endmodule
