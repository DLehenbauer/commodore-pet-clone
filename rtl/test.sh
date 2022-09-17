iverilog -g2012 spi.v tb_spi.v tb_common.v && vvp a.out
iverilog -g2012 spi.v tb_spi_buffer.v tb_common.v && vvp a.out
iverilog -g2012 spi.v tb_spi_pi.v tb_common.v && vvp a.out