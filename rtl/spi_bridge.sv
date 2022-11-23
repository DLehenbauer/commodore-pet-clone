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
    output logic spi_rw_no   = 1'b1,
    output logic spi_valid_o,
    input  logic spi_ready_i,
    output logic spi_ready_o,
    
    // Expose internal state for debugging
    output logic [3:0] state = READ_CMD,
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

    logic cmd_rw_n;
    logic cmd_rd_a;

    //                                RV
    localparam READ_CMD          = 4'b0000,
               READ_DATA_ARG     = 4'b0001,
               READ_ADDR_HI_ARG  = 4'b0010,
               READ_ADDR_LO_ARG  = 4'b0011,
               XFER              = 4'b0100,
               DONE              = 4'b1000;

    assign spi_valid_o = state[2];
    assign spi_ready_o = state[3];

    always_ff @(posedge clk_sys_i or posedge reset) begin
        if (reset) begin
            state <= READ_CMD;
        end else begin
            unique case (state)
                READ_CMD: begin
                    if (rx_valid) begin
                        spi_rw_no <= rx[7];
                        cmd_rd_a  <= rx[6];

                        // If CMD sets address capture A16 from rx[0] now.
                        if (rx[6]) spi_addr_o <= { rx[0], 16'hxxxx };

                        unique casez(rx)
                            8'b0???????: state <= READ_DATA_ARG;
                            8'b11??????: state <= READ_ADDR_HI_ARG;
                            default:     state <= XFER;
                        endcase
                    end
                end

                READ_DATA_ARG: begin
                    if (rx_valid) begin
                        spi_data_o <= rx;
                        state <= cmd_rd_a
                            ? READ_ADDR_HI_ARG
                            : XFER;
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
                    if (spi_ready_i) begin
                        spi_addr_o <= spi_addr_o + 1'b1;
                        state <= DONE;
                    end
                end

                default: /* DONE */;
            endcase
        end
    end
endmodule
