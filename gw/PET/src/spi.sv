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

// Implements core of SPI Mode 0 byte transfers in a controller/peripheral agnostic way.
module spi_byte (
    input  logic spi_cs_ni,         // CS_N also functions as an asynchronous reset
    input  logic spi_sck_i,         // SCK must be low before falling edge of CS_N
    input  logic spi_rx_i,
    output logic spi_tx_o,
    
    input  logic [7:0] tx_byte_i,   // Byte transmitted.  Captured on falling edge of CS_N and
                                    // negative edge last falling edge of SCK.

    output logic [7:0] rx_byte_o,   // Received byte shift register contents
    output logic en_o = '0
);
    logic valid_d;
    logic [2:0] bit_count;
    logic [7:0] rx_byte_q;
    logic [7:0] tx_byte;

    always_comb begin
        en_o = bit_count == 3'd7;
    end

    always_latch begin
        if (!spi_sck_i) rx_byte_o <= { rx_byte_q[6:0], spi_rx_i };
    end

    always_ff @(posedge spi_cs_ni or posedge spi_sck_i) begin
        if (spi_cs_ni) begin
            bit_count <= '0;
            rx_byte_q <= 8'hxx;
        end else begin
            rx_byte_q <= rx_byte_o;
            bit_count <= bit_count + 1'b1;
        end
    end

    always_ff @(negedge spi_cs_ni or negedge spi_sck_i) begin
        if (spi_sck_i) begin
            tx_byte  <= tx_byte_i;
            spi_tx_o <= tx_byte_i[7];
        end else begin
            if (bit_count == '0) begin
                tx_byte  <= tx_byte_i;
                spi_tx_o <= tx_byte_i[7];
            end else begin
                tx_byte  <= { tx_byte[6:0], 1'bx };
                spi_tx_o <= tx_byte[6];
            end
        end
    end
endmodule

// Protocol for SPI1 peripheral
module spi1(
    input  logic clk_i,                 // Destination clock domain

    input  logic spi_sck_i,             // SCK
    input  logic spi_cs_ni,             // CS: Also serves as a synchronous reset for the SPI FSM
    input  logic spi_rx_i,              // PICO
    output logic spi_tx_o,              // POCI
    
    output logic        spi_valid_o,    // Next SPI command received: '_addr_o', '_data_o', and '_rw_no' are valid.
    output logic [16:0] spi_addr_o,     // Bus address of pending read/write command
    input  logic  [7:0] spi_data_i,     // Data returned from completed read command
    output logic  [7:0] spi_data_o,     // Data to be written by pending write command
    output logic        spi_rw_no       // Direction of pending command (0 = write, 1 = read)
);
    logic [7:0] spi_rx;
    logic       spi_en;

    spi_byte spi_byte(
        .spi_sck_i(spi_sck_i),
        .spi_cs_ni(spi_cs_ni),
        .spi_rx_i(spi_rx_i),
        .spi_tx_o(spi_tx_o),
        .rx_byte_o(spi_rx),
        .tx_byte_i(spi_data_i),
        .en_o(spi_en)
    );

    // State encoding for our FSM:
    //
    //  D = data        (processing a write command, awaiting byte to write)
    //  A = address     (processing a random access command, awaiting address bytes)
    //  V = spi_valid_o (a command has been received)
    //  R = spi_ready_o (signals to MCU that command has finished processing)
    //
    //                                RVAD
    localparam READ_CMD          = 4'b0000,
               READ_DATA_ARG     = 4'b0001,
               READ_ADDR_HI_ARG  = 4'b0010,
               READ_ADDR_LO_ARG  = 4'b0011,
               VALID             = 4'b0100,
               DONE              = 4'b1000;

    logic [3:0] state = READ_CMD;   // Current state of FSM

    // Asserted if current CMD reads the target address, in which case FSM will
    // transition through READ_ADDR_*_ARG before the VALID state.
    logic cmd_rd_a;

    always_ff @(posedge spi_cs_ni or posedge spi_sck_i) begin
        if (spi_cs_ni) begin
            // Deasserting CS_N synchronously resets the FSM.
            state <= READ_CMD;
        end else begin
            // 'spi_rx' is valid When 'spi_en' is asserted on the positive SCK edge.
            // Advance the FSM before the next SCK edge shifts 'spi_rx'.
            if (spi_en) begin
                unique case (state)
                    READ_CMD: begin
                        spi_rw_no <= spi_rx[7];
                        cmd_rd_a  <= spi_rx[6];

                        if (spi_rx[6]) begin
                            // If the incomming CMD reads target address as an argument, capture A16 from rx[0] now.
                            spi_addr_o <= { spi_rx[0], 16'hxxxx };
                        end else begin
                            // Otherwise increment the previous address.
                            spi_addr_o <= spi_addr_o + 1'b1;
                        end

                        unique casez(spi_rx)
                            8'b0???????: state <= READ_DATA_ARG;
                            8'b11??????: state <= READ_ADDR_HI_ARG;
                            default:     state <= VALID;
                        endcase
                    end

                    READ_DATA_ARG: begin
                        spi_data_o <= spi_rx;
                        state <= cmd_rd_a
                            ? READ_ADDR_HI_ARG
                            : VALID;
                    end

                    READ_ADDR_HI_ARG: begin
                        spi_addr_o <= { spi_addr_o[16], spi_rx, 8'hxx };
                        state      <= READ_ADDR_LO_ARG;
                    end

                    READ_ADDR_LO_ARG: begin
                        spi_addr_o <= { spi_addr_o[16:8], spi_rx };
                        state      <= VALID;
                    end

                    VALID: begin
                        // Remain in the valid state until positve CS_N edge resets the FSM.
                        state <= VALID;
                    end
                endcase
            end
        end
    end

    // 'state[2]' bit indicates 'state == VALID'.  Sychronize this transition to the
    // FPGA clock domain and output as 'spi_valid_o'.
    sync2 sync_valid(
        .clk_i(clk_i),
        .data_i(state[2]),
        .data_o(spi_valid_o)
    );
endmodule
