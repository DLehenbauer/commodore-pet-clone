module spi_byte (
    input  spi_sclk,
    input  spi_cs_n,        // SPI chip select also doubles as an asyncronous reset
    input  spi_rx,
    inout  spi_tx,

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Loaded on rising edge of 'spi_sclk' when 'done'.

    output reg done = 1'b0
);
    reg [2:0] bit_count = 3'd0;
    reg [7:0] data_tx;

    always @(posedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            bit_count <= 0;
            done <= 0;
        end else begin
            if (!spi_cs_n) begin
                if (bit_count == 0) begin
                    data_tx <= tx;
                    rx <= { 7'b0000000, spi_rx };
                end else begin
                    data_tx[7:1] <= data_tx[6:0];
                    rx <= { rx[6:0], spi_rx };
                end

                done <= bit_count == 8'd7;
                bit_count <= bit_count + 1'b1;
            end
        end
    end

    assign spi_tx = spi_cs_n
        ? 1'bz
        : data_tx[7];
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