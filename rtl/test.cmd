setlocal ENABLEDELAYEDEXPANSION
:: iverilog -g2012 crtc.sv tb_crtc.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 spi.sv tb_spi_pi.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 spi.sv tb_spi.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 video.sv bus.sv tb_video.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 bus.sv tb_bus.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 keyboard.sv tb_keyboard.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 sync.sv bus.sv tb_sync.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 address_decoding.sv tb_address_decoding.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
