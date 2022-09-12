module spi_byte (
    input  spi_sclk,
    input  spi_cs_n,        // SPI chip select also doubles as an asyncronous reset
    input  spi_rx,
    output spi_tx,

    output reg [7:0] rx,    // Byte recieved.  Valid on rising edge of 'done'.
    input      [7:0] tx,    // Byte to transmit.  Loaded on rising edge of 'spi_sclk' when 'done'.

    output reg done = 1
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
            done <= 0;
        end else begin
            tx_bit_index <= tx_bit_index - 1'b1;
            done <= tx_bit_index == 3'd0;
        end
    end

    assign spi_tx = tx[tx_bit_index];
endmodule

module pi_register(
    input spi_sclk,
    input spi_cs_n,
    input spi_rx,
    output spi_tx,
    output [16:0] pi_addr,
    output [7:0] pi_data,
    output pi_rw_b,
    output pi_pending
);
    wire [7:0] rx;
    reg [7:0] tx = 8'h00;
    wire byte_done;

    spi_byte spi(
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_rx(spi_rx),
        .spi_tx(spi_tx),
        .rx(rx),
        .tx(tx),
        .done(byte_done)
    );

    reg [7:0] r [4];
    reg [2:0] in_count = 0;

    always @(posedge byte_done) begin
        in_count <= in_count + 1'b1;
    end

    assign pi_pending = in_count[2];
    assign pi_rw_b = { r[0][7] };
    assign pi_addr = { r[0][0], r[1], r[2] };
    assign pi_data = { r[3] };
endmodule
