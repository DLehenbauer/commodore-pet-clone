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

module spi_register(
    input reset,
    input spi_sclk,
    input spi_rx,
    output done
);
    wire [7:0] rx;
    wire byte_done;

    reg [7:0] bytes [2:0];
    reg [1:0] byte_count = 0;

    spi_byte rx_byte(
        .spi_sclk(spi_sclk),
        .spi_cs_n(reset),       // 'cs_n' doubles as an asynchronous reset
        .spi_rx(spi_rx),
        .rx(rx),
        .done(byte_done)
    );

    always @(posedge byte_done or posedge reset) begin
        if (reset) begin
            byte_count <= 0;
        end else begin
            bytes[byte_count] <= rx;
            byte_count <= byte_count + 1'b1;
        end
    end
endmodule