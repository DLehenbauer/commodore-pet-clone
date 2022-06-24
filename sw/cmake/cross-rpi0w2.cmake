# PET Clone - Open hardware implementation of the Commodore PET
# by Daniel Lehenbauer and contributors.
# 
# https://github.com/DLehenbauer/commodore-pet-clone
#
# To the extent possible under law, I, Daniel Lehenbauer, have waived all
# copyright and related or neighboring rights to this project. This work is
# published from the United States.
#
# @copyright CC0 http://creativecommons.org/publicdomain/zero/1.0/
# @author Daniel Lehenbauer <DLehenbauer@users.noreply.github.com> and contributors

set(tools /usr)
include(${CMAKE_CURRENT_LIST_DIR}/cross-rpi.cmake)

set(CMAKE_LIBRARY_ARCHITECTURE arm-linux-gnueabihf)

# Link time optimization for Raspberry Pi Zero W 2, 3 & 4 Model A+/B+ & Compute 3/3-lite/3+ (32-Bit)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -march=armv8-a -mfloat-abi=hard -mfpu=neon-fp-armv8")

# Link time optimization for Raspberry Pi 3 & 4 Model A+/B+ & Compute 3/3-lite/3+ (64-Bit)
#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -march=armv8-a+fp+simd")
