cmake_minimum_required(VERSION 3.13)

if (TARGET tinyusb_device)
    set(FAMILY rp2040)
    set(BOARD pico_sdk)
    set(TINYUSB_FAMILY_PROJECT_NAME_PREFIX "tinyusb_host_")

    add_executable(firmware
        global.c
        main.c
        usb/hid_app.c
        usb/keyboard.c
        usb/usb.c
    )

    target_precompile_headers(firmware PRIVATE pch.h)

    # Make sure TinyUSB can find tusb_config.h
    target_include_directories(firmware PUBLIC
        ${CMAKE_CURRENT_LIST_DIR})

    # pull in common dependencies
    target_link_libraries(firmware pico_stdlib hardware_spi tinyusb_host tinyusb_board)

    # create map/bin/hex/uf2 file etc.
    pico_add_extra_outputs(firmware)
elseif(PICO_ON_DEVICE)
    message(WARNING "not building firmware because TinyUSB submodule is not initialized in the SDK")
endif()
