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
    input  logic spi_cs_ni,             // CS_N also functions as an asynchronous reset
    input  logic spi_sck_i,             // SCK must be low before falling edge of CS_N
    input  logic spi_rx_i,
    output logic spi_tx_o,
    
    input  logic [7:0] tx_byte_i,       // Byte to transmit.  Captured on falling edge of CS_N and
                                        // falling edge of SCK for LSB.

    output logic [7:0] rx_byte_o,       // Received byte shift register contents
    output logic       rx_valid_o       // Asserted during rising edge of SCK when 'rx_byte_o' has latched
);                                      // a full byte.  Reset on next SCK or rising CS_N.
    logic valid_d;
    logic [2:0] bit_count = 3'd0;
    logic [7:0] rx_byte_q;
    logic [7:0] tx_byte;

    always_comb begin
        rx_valid_o = bit_count == 3'd7;
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

module spi1_master #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 17
) (
    input  logic                    clk_i,              // Bus clock

    output logic [ADDR_WIDTH-1:0]   addr_o,             // Address of pending read/write (valid when 'cycle_o' asserted)
    output logic [DATA_WIDTH-1:0]   wr_data_o,          // Data received from MCU to write (valid when 'cycle_o' asserted)
    input  logic [DATA_WIDTH-1:0]   rd_data_i,          // Data to transmit to MCU (valid when 'ack_i' asserted)
    output logic                    we_o,               // Direction of bus transfer (0 = reading, 1 = writing)
    
    output logic                    cycle_o = '0,       // Requests a bus cycle from the arbiter
    input  logic                    ack_i,              // Signals termination of cycle ('rd_data_i' valid)

    // SPI
    input  logic                    spi_sck_i,          // SCK
    input  logic                    spi_cs_ni,          // CS_N: Negative captures 'rd_data_i' and resets FSM
    input  logic                    spi_rx_i,           // MOSI: MCU -> FPGA
    output logic                    spi_tx_o,           // MISO: FPGA -> MCU
    output logic                    spi_ready_o = 1'b1  // Ready for next SPI command / previous command completed
);
    logic [7:0] spi_rx;
    logic       spi_rx_valid;
    logic [7:0] spi_tx_byte;

    spi_byte spi_byte(
        .spi_sck_i(spi_sck_i),
        .spi_cs_ni(spi_cs_ni),
        .spi_rx_i(spi_rx_i),
        .spi_tx_o(spi_tx_o),
        .rx_byte_o(spi_rx),
        .tx_byte_i(spi_tx_byte),
        .rx_valid_o(spi_rx_valid)
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
               VALID             = 4'b0100;

    logic [3:0] state = READ_CMD;   // Current state of FSM

    // Asserted if current CMD reads the target address, in which case FSM will
    // transition through READ_ADDR_*_ARG before the VALID state.
    logic cmd_rd_a;

    always_ff @(negedge spi_cs_ni or posedge spi_sck_i) begin
        if (!spi_sck_i) begin
            // Deasserting CS_N asynchronously resets the FSM.
            state <= READ_CMD;
        end else begin
            // 'spi_rx' is valid When 'spi_rx_valid' is asserted on the positive SCK edge.
            // Advance the FSM before the next SCK edge shifts 'spi_rx'.
            if (spi_rx_valid) begin
                unique case (state)
                    READ_CMD: begin
                        we_o <= !spi_rx[7];     // Capture transfer direction (0 = reading, 1 = writing)
                        cmd_rd_a <= spi_rx[6];

                        if (spi_rx[6]) begin
                            // If the incomming CMD reads target address as an argument, capture A16 from rx[0] now.
                            addr_o <= { spi_rx[0], 16'hxxxx };
                        end else begin
                            // Otherwise increment the previous address.
                            addr_o <= addr_o + 1'b1;
                        end

                        unique casez(spi_rx)
                            8'b0???????: state <= READ_DATA_ARG;
                            8'b11??????: state <= READ_ADDR_HI_ARG;
                            default:     state <= VALID;
                        endcase
                    end

                    READ_DATA_ARG: begin
                        wr_data_o <= spi_rx;
                        state <= cmd_rd_a
                            ? READ_ADDR_HI_ARG
                            : VALID;
                    end

                    READ_ADDR_HI_ARG: begin
                        addr_o <= { addr_o[16], spi_rx, 8'hxx };
                        state      <= READ_ADDR_LO_ARG;
                    end

                    READ_ADDR_LO_ARG: begin
                        addr_o <= { addr_o[16:8], spi_rx };
                        state      <= VALID;
                    end

                    VALID: begin
                        // Remain in the valid state until negative CS_N edge resets the FSM.
                        state <= VALID;
                    end
                endcase
            end
        end
    end

    logic cmd_valid_pe;

    sync2_edge_detect sync_valid(   // Cross from SCK to 'clk_i' domain
        .clk_i(clk_i),
        .data_i(state[2]),          // 'state[2]' bit indicates 'state == VALID'.
        .pe_o(cmd_valid_pe)
    );

    logic spi_reset_pe;

    sync2_edge_detect sync_cs_n(    // Cross from CSN to 'clk_i' domain
        .clk_i(clk_i),
        .data_i(!spi_cs_ni),
        .pe_o(spi_reset_pe)
    );

    // MCU/FPGA handshake works as follows:
    // - MCU waits for FPGA to assert READY
    // - MCU asserts CS_N (resets FSM -> cmd_valid_ne pulse)
    // - MCU transmits bytes (advances FSM to VALID state -> cmd_valid_pe)
    // - MCU waits for FPGA to assert READY (ack_i -> spi_ready_o)
    // - MCU deasserts CS_N (no effect)

    always_ff @(posedge clk_i) begin
        if (spi_reset_pe) begin
            // MCU has asserted CS_N.
            spi_ready_o <= '0;
            cycle_o <= '0;
        end else if (cmd_valid_pe) begin
            // MCU has finished transmitting command:
            cycle_o <= 1'b1;            // Request bus cycle from arbiter.
        end if (ack_i) begin
            // Requested bus cycle has terminated:
            cycle_o <= '0;              // Bus cycle has completed.
            spi_tx_byte <= rd_data_i;   // Capture 'rd_data_i' to transmit on next cmd.
            spi_ready_o <= 1'b1;            // Notify MCU we're ready for next cmd.
        end
    end
endmodule
