iverilog -g2012 \
    address_decoding.sv \
    bus.sv \
    control.sv \
    crtc.sv \
    keyboard.sv \
    main.sv \
    main_tb.sv \
    pe_pulse.sv \
    spi.sv \
    spi_bridge.sv \
    spi_buffer.sv \
    sync.sv \
    timing.sv \
    video.sv
vvp a.out
