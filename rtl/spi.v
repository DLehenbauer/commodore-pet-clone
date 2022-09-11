module spi_byte (
    input  spi_sclk,
    input  spi_cs_n,        // SPI chip select also doubles as an asyncronous reset
    input  spi_rx,
    output spi_tx,

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Loaded on rising edge of 'spi_sclk' when 'done'.

    output done
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
        end else begin
            tx_bit_index <= tx_bit_index - 1'b1;
        end
    end

    assign spi_tx = tx[tx_bit_index];
    assign done = !spi_sclk & tx_bit_index == 3'd7;
endmodule

// commands:
//
// 0000 |   xxx   |  x  : NOP
// 0001 |    2    | A16 : WRITE <A15:0> <D7:0>
// 0010 |    2    | A16 : READ  <A15:0> <D7:0>

// module spi_cmd(
//     input reset,
//     input spi_sclk,
//     input spi_rx,
//     input pi_select,
//     input pi_strobe,
//     output pi_addr,
//     output pi_data,
//     output pi_rw_b
// );
//     wire sclk = spi_sclk;
//     wire [7:0] rx;

//     spi_byte spi_byte(
//         .spi_sclk(sclk),
//         .spi_cs_n(spi_cs_n),
//         .spi_rx(spi_rx),
//         .done(byte_done)
//     );

//     localparam WAITING_FOR_CMD = 0,
//                PENDING_READ    = 1,
//                PENDING_WRITE   = 2;

//     reg [7:0] state = WAITING_FOR_CMD;
//     reg [7:0] bytes [8];

//     always @(posedge byte_done or reset) begin
//         if (reset) begin
//             state <= 0;
//         end else begin
//             if (state == WAITING_FOR_CMD) begin
//                 state <= rx;
//             end else if (state[3:1]) begin
//                 bytes[state[3:1]] <= rx;

//                 if (state[3:1] == 1) begin
//                     case (state[7:4])
//                         PENDING_READ: ;
//                     endcase
//                 end

//                 state[3:1] <= state[3:1] - 1'b1;
//             end
//         end
//     end
// endmodule