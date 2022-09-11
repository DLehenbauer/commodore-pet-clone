module spi_slave (
    input  spi_sclk,
    input  spi_cs_n,
    input  spi_mosi,
    output spi_miso,

    input      [7:0] tx,
    output reg [7:0] rx,

    output done
);
    reg [2:0] bit_count = 0;
    reg [7:0] data_tx;

    assign done = bit_count == 0;

    always @(posedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            bit_count <= 0;
        end else begin
            if (spi_cs_n) begin
                if (done) begin
                    data_tx <= tx;
                    rx <= { 7'b0000000, spi_mosi };
                end else begin
                    data_tx[7:1] <= data_tx[6:0];
                    rx <= { rx[6:0], spi_mosi };
                end

                bit_count <= bit_count + 1'b1;
            end
        end
    end

    assign spi_miso = spi_cs_n
        ? 1'bz
        : data_tx[7];
endmodule