if (TARGET tinyusb_device)
    add_executable(firmware
            main.c
            )

    # pull in common dependencies
    target_link_libraries(firmware pico_stdlib hardware_spi)

    # create map/bin/hex/uf2 file etc.
    pico_add_extra_outputs(firmware)
elseif(PICO_ON_DEVICE)
    message(WARNING "not building firmware because TinyUSB submodule is not initialized in the SDK")
endif()
