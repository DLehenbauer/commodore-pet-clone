# Derived from abhiTronix's Raspberry Pi Toolchain v3
# See: https://github.com/abhiTronix/raspberry-pi-cross-compilers/wiki/Cross-Compiler-CMake-Usage-Guide-with-rsynced-Raspberry-Pi-32-bit-OS#cross-compiler-cmake-usage-guide-with-rsynced-raspberry-pi-32-bit-os
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(rootfs_dir /opt/rpi/sysroot)
set(CMAKE_FIND_ROOT_PATH ${rootfs_dir})
set(CMAKE_SYSROOT ${rootfs_dir})

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")

## Compiler Binary
set(BIN_PREFIX ${tools}/bin/${CMAKE_LIBRARY_ARCHITECTURE})
set(CMAKE_C_COMPILER ${BIN_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${BIN_PREFIX}-g++ )
set(CMAKE_LINKER ${BIN_PREFIX}-ld CACHE STRING "Set the cross-compiler tool LD" FORCE)
set(CMAKE_AR ${BIN_PREFIX}-ar CACHE STRING "Set the cross-compiler tool AR" FORCE)
set(CMAKE_NM ${BIN_PREFIX}-nm CACHE STRING "Set the cross-compiler tool NM" FORCE)
set(CMAKE_OBJCOPY ${BIN_PREFIX}-objcopy CACHE STRING "Set the cross-compiler tool OBJCOPY" FORCE)
set(CMAKE_OBJDUMP ${BIN_PREFIX}-objdump CACHE STRING "Set the cross-compiler tool OBJDUMP" FORCE)
set(CMAKE_RANLIB ${BIN_PREFIX}-ranlib CACHE STRING "Set the cross-compiler tool RANLIB" FORCE)
set(CMAKE_STRIP ${BIN_PREFIX}-strip CACHE STRING "Set the cross-compiler tool STRIP" FORCE)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
