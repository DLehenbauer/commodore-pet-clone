setlocal ENABLEDELAYEDEXPANSION
iverilog -g2012 tb_dotgen.sv crtc.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_crtc_sync_gen.sv crtc.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_crtc.sv crtc.sv address_decoding.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_spi.sv spi.sv pe_pulse.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_spi_bridge.sv spi_bridge.sv spi.sv spi_driver.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_video.sv video.sv bus.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_bus.sv bus.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_keyboard.sv keyboard.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_sync.sv sync.sv bus.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
iverilog -g2012 tb_address_decoding.sv address_decoding.sv tb_common.sv && vvp a.out || exit /b !ERRORLEVEL!
