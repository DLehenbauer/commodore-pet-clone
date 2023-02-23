cmake_minimum_required(VERSION 3.13)

add_subdirectory("external/PicoDVI/software/libdvi")
add_subdirectory("external/no-OS-FatFS-SD-SPI-RPi-Pico/FatFs_SPI")

if (TARGET tinyusb_device)
    set(FAMILY rp2040)
    set(BOARD pico_sdk)
    
    # TODO: 'TINYUSB_FAMILY_PROJECT_NAME_PREFIX' copied pico examples.  Is this used?
    set(TINYUSB_FAMILY_PROJECT_NAME_PREFIX "tinyusb_host_")

    add_executable(firmware
        driver.c
        dvi/dvi.c
        global.c
        main.c
        pet.c
        sd/sd.c
        test.c
        usb/cdc_app.c
        usb/hid_app.c
        usb/msc_app.c
        usb/keyboard.c
        usb/usb.c
    )

    # See https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf#errata-e5
    # target_compile_definitions(firmware PRIVATE PICO_RP2040_USB_DEVICE_ENUMERATION_FIX=1)

    # To change the default serial config for all apps, pass e.g.
    #   cmake -DDVI_DEFAULT_SERIAL_CONFIG=pimoroni_demo_hdmi_cfg ..
    # then rebuild. This is applied via target_compile_definitions on each app
    # individually.
    set(DVI_DEFAULT_SERIAL_CONFIG "pico_sock_cfg" CACHE STRING
        "Select a default pin configuration from common_dvi_pin_configs.h")

    include_directories(
        "external/PicoDVI/software/assets"
        "external/PicoDVI/software/include"
        "external/no-OS-FatFS-SD-SPI-RPi-Pico/FatFS_SPI/include")

    # target_compile_definitions(firmware PRIVATE
    #     DVI_VERTICAL_REPEAT=1
    #     DVI_N_TMDS_BUFFERS=3
    #     DVI_1BPP_BIT_REVERSE=1
    #     DVI_MONOCHROME_TMDS)

    target_precompile_headers(firmware PRIVATE pch.h)

    # Make sure TinyUSB can find tusb_config.h
    target_include_directories(firmware PUBLIC
        ${CMAKE_CURRENT_LIST_DIR})

    # pull in common dependencies
    target_link_libraries(firmware
        pico_stdlib
        pico_multicore
        pico_util
        hardware_spi
        tinyusb_host
        tinyusb_board
        libdvi
        FatFs_SPI)

    # create map/bin/hex/uf2 file etc.
    pico_add_extra_outputs(firmware)
elseif(PICO_ON_DEVICE)
    message(WARNING "not building firmware because TinyUSB submodule is not initialized in the SDK")
endif()
