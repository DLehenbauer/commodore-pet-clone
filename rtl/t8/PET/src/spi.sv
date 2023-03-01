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
    input  logic clk_sys_i,         // Sampling clock

    input  logic spi_cs_ni,         // CS_N also functions as a synchronous reset
    input  logic spi_sck_i,         // SCK must be low before falling edge of CS_N
    input  logic spi_rx_i,
    output logic spi_tx_o,

    output logic [7:0] rx_byte_o,   // Byte recieved.  Valid on rising edge of 'valid'.
    input  logic [7:0] tx_byte_i,   // Byte to transmit.  Loaded on falling edges of CS_N and last SCLK of byte.

    output logic valid_o            // 'rx_byte' valid pulse is high for one period of clk_sys_i.
);
    // Signals crossing clock domain
    logic spi_cs_nq;
    logic spi_sck_q;
    logic spi_rx_q;
    logic spi_tx_d;

    // Shift register simultaneously clocks in the incoming 'rx' bit at 'sr[0]' and clocks out
    // the outgoing 'tx' bit at 'sr[7]'.
    logic [7:0] sr_d, sr_q;

    // Counts the number of bits transfered in the current byte.  Used to detect when to copy
    // 'sr' to 'rx_byte', assert 'valid', and load the next 'tx_byte'.
    logic [2:0] bit_count_d, bit_count_q = '0;

    // 'sr' is copied to 'rx_byte' on the rising edge of the 'valid' pulse.
    logic [7:0] rx_byte_d;
    logic valid_d;

    // Detect positive and negative edges of 'spi_sck_q'.
    logic spi_sck_q2;
    wire spi_sck_pe = !spi_sck_q2 &&  spi_sck_q;
    wire spi_sck_ne =  spi_sck_q2 && !spi_sck_q;

    always_comb begin
        // Signals crossing clock domain
        spi_tx_d    = spi_tx_o;        
        sr_d        = sr_q;
        bit_count_d = bit_count_q;
        rx_byte_d   = rx_byte_o;
        valid_d     = '0;

        if (spi_cs_nq) begin
            // Deasserting 'CS' resets the SPI state machine.
            bit_count_d = '0;

            // Reset 'valid' pulse
            valid_d     = '0;

            // Preload 'tx_byte' while 'CS' is deasserted so it is ready to transfer on the
            // first 'SCK'.
            sr_d        = tx_byte_i;
            spi_tx_d    = tx_byte_i[7];
        end else begin
            if (spi_sck_pe) begin
                // On the positive edge of 'spi_sck' we shift the incoming 'rx' bit into 'sr'
                // and incement our 'bit_count'.  This simultaneously shifts the next outgoing
                // bit of 'tx_byte' to sr[7].
                sr_d        = { sr_q[6:0], spi_rx_q };
                bit_count_d = bit_count_q + 1'b1;

                if (bit_count_q == 3'd7) begin
                    // We've received the last bit of 'rx_byte'.  Store it in 'rx_byte' and raise
                    // the 'valid' pulse.
                    rx_byte_d = { sr_q[6:0], spi_rx_q };
                    valid_d   = 1'b1;
                end
            end else if (spi_sck_ne) begin
                if (bit_count_q == 3'd0) begin
                    // We transmitted the last bit of the previous 'tx_byte' on the positive edge
                    // of SCLK.  Load the next value of 'tx_byte' into 'sr' on the negative edge.
                    sr_d     = tx_byte_i;
                    spi_tx_d = tx_byte_i[7];
                end else begin
                    // Prepare 'spi_tx' with the next outgoing bit of 'tx_byte' so it's available
                    // on the next positive edge SCLK.
                    spi_tx_d = sr_q[7];
                end
            end
        end
    end

    always_ff @(posedge clk_sys_i) begin
        bit_count_q <= bit_count_d;
        sr_q        <= sr_d;

        spi_cs_nq   <= spi_cs_ni;
        spi_sck_q  <= spi_sck_i;
        spi_sck_q2 <= spi_sck_q;
        spi_rx_q    <= spi_rx_i;
        spi_tx_o    <= spi_tx_d;

        rx_byte_o   <= rx_byte_d;
        valid_o     <= valid_d;
    end
endmodule

// Protocol for SPI1 peripheral
module spi1(
    input  logic clk_sys_i,         // Sampling / FSM clock

    input  logic spi_sck_i,         // SCK
    input  logic spi_cs_ni,         // CS: Also serves as a synchronous reset for the SPI FSM
    input  logic spi_rx_i,          // PICO
    output logic spi_tx_o,          // POCI

    output logic spi_valid_o,       // Next SPI command received: '_addr_o', '_data_o', and '_rw_no' are valid.
    input  logic spi_ready_i,       // Previous SPI command internally processed.  Updates SPI FSM.
    output logic spi_ready_o,       // External signal to MCU that previous SPI has completed.

    output logic [16:0] spi_addr_o, // Bus address of pending read/write command
    input  logic  [7:0] spi_data_i, // Data returned from completed read command
    output logic  [7:0] spi_data_o, // Data to be written by pending write command
    output logic        spi_rw_no   // Direction of pending command (0 = write, 1 = read)
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
               XFER              = 4'b0100,
               DONE              = 4'b1000;

    logic [3:0] state = READ_CMD;   // Current state of FSM
    logic       rx_valid;           // Asserted by 'spi_byte' when a byte has been received
    logic [7:0] rx;                 // Next received byte to decode
    
    spi_byte spi_byte(
        .clk_sys_i(clk_sys_i),
        .spi_sck_i(spi_sck_i),
        .spi_cs_ni(spi_cs_ni),
        .spi_rx_i(spi_rx_i),
        .spi_tx_o(spi_tx_o),
        .rx_byte_o(rx),
        .tx_byte_i(spi_data_i),
        .valid_o(rx_valid)
    );
    
    logic cmd_rd_a;

    assign spi_valid_o = state[2];
    assign spi_ready_o = state[3];

    always_ff @(posedge clk_sys_i or posedge spi_cs_ni) begin
        if (spi_cs_ni) begin
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

                default: /* DONE */ begin
                    // Remain in 'DONE' state until '_cs_n' is deasserted, signaling that the
                    // MCU is beginning a new command.
                    //
                    // TODO: Review if DONE and READ_CMD could be a single state.
                end
            endcase
        end
    end
endmodule
