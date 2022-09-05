setlocal /ENABLEDELAYEDEXPANSION
:: iverilog -g2012 crtc.v tb_crtc.v tb_common.v && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 video.v tb_video.v tb_common.v && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 bus.v tb_bus.v tb_common.v && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 keyboard.v tb_keyboard.v tb_common.v && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 sync.v bus.v tb_sync.v tb_common.v && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 address_decoding.v tb_address_decoding.v tb_common.v && vvp a.out || exit /b !ERRORLEVEL!
