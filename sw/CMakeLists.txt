# PET Clone - Open hardware implementation of the Commodore PET
# by Daniel Lehenbauer (and contributors).
# 
# https://github.com/DLehenbauer/commodore-pet-clone
#
# To the extent possible under law, I, Daniel Lehenbauer, have waived all
# copyright and related or neighboring rights to this project. This work is
# published from the United States.
#
# @copyright CC0 http://creativecommons.org/publicdomain/zero/1.0/
# @author Daniel Lehenbauer <DLehenbauer@users.noreply.github.com> and contributors

set(CMAKE_VERBOSE_MAKEFILE ON)
cmake_minimum_required(VERSION 3.13.1)
include(FetchContent)

project(main)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")
set(CMAKE_MAKE_PROGRAM "make")

add_executable(main src/display.cpp src/driver.cpp src/gpio.cpp src/main.cpp src/trace.cpp)
target_precompile_headers(main PRIVATE src/pch.hpp)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

find_package(Boost 1.74 COMPONENTS system REQUIRED)
set(Boost_USE_STATIC_LIBS       OFF)
set(Boost_USE_DEBUG_LIBS         ON)
set(Boost_USE_RELEASE_LIBS      OFF)
set(Boost_USE_MULTITHREADED      ON)
set(Boost_USE_STATIC_RUNTIME    OFF)

find_package(SDL2 REQUIRED)

include_directories(
    ${Boost_INCLUDE_DIRS}
    ${SDL2_INCLUDE_DIR})

target_link_libraries(${PROJECT_NAME}
    ${Boost_LIBRARIES}
    ${SDL2_LIBRARIES}
    Threads::Threads
    bcm_host)

set(CMAKE_TLS_VERIFY true)

function(download_rom url hash)
    FetchContent_Declare("download-${hash}"
        URL ${url}
        URL_HASH MD5=${hash}
        DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/bin/roms
        DOWNLOAD_NO_EXTRACT true
    )

    list(APPEND rom_downloads "download-${hash}")
    set (rom_downloads ${rom_downloads} PARENT_SCOPE)
endfunction()

# US Character Set
download_rom(http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/characters-2.901447-10.bin 9880432E633B15998D58884FF34C4E70)

# BASIC 4.0
download_rom(http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/basic-4-b000.901465-23.bin 43B3A9F5E1C762AF0B3BB6CC71AAFB84)
download_rom(http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/basic-4-c000.901465-20.bin 398217F35FA50417C7E84883A93A349B)
download_rom(http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/basic-4-d000.901465-21.bin AB780E94772DCA756A0678A17B5BC3A2)
download_rom(http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/edit-4-n.901447-29.bin 6FE27B43EC550A04D30B2E45F07D51FB)
download_rom(http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/kernal-4.901465-22.bin 16EC21443EA5431AB63D511061054E6F)

# BASIC 4.0, 40C, GFX KBD, 60Hz, CRTC
download_rom(http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/edit-4-80-b-60Hz.901474-03.bin DA56995BE008C5F7DB1094E81E5060AA)

# BASIC 4.0, 40C, GFX KBD, 50Hz, CRTC
download_rom(http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/edit-4-40-n-50Hz.901498-01.bin B76D756E7AC8752AE0035F3CE5F1383C)

FetchContent_MakeAvailable(${rom_downloads})

add_custom_target(deploy
    DEPENDS main
    COMMAND ssh ${PI_HOST} "sudo killall -9 gdb\; sudo killall -9 main\; sudo killall -9 scp\; true"
    COMMAND scp -r ${CMAKE_CURRENT_BINARY_DIR}/bin/* ${PI_HOST}:~
)
