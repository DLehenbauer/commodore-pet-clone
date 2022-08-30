iverilog -g2012 sync.v tb_sync.v tb_common.v && vvp a.out
iverilog -g2012 bus.v tb_bus.v tb_common.v && vvp a.out
iverilog -g2012 address_decoding.v tb_address_decoding.v tb_common.v && vvp a.out
iverilog -g2012 keyboard.v tb_keyboard.v tb_common.v && vvp a.out