# Ubuntu to support Efinix FPGA toolchain:
# https://www.efinixinc.com/support/efinity.php

# See here for image contents: https://github.com/devcontainers/images/tree/main/src/base-ubuntu

# [Choice] Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): ubuntu-22.04, ubuntu-20.04, ubuntu-18.04
ARG VARIANT=jammy
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# Currently targetted SDK version
ARG PICO_SDK_VERSION="1.5.0"

# Use unattended mode for 'apt'
ARG DEBIAN_FRONTEND="noninteractive"

# Raspberry Pi Pico SDK
ARG PICO_PATH="/opt/pico"
WORKDIR $PICO_PATH

# Install cross toolchain for Raspberry Pi Pico.  Note that we also need
# the native toolchain in order to build the 'pioasm' and 'elf2uf2' tools.
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    cmake \
    gcc-arm-none-eabi \
    gdb-multiarch \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib

# Get Raspberry Pi Pico SDK
RUN git clone --depth 1 --branch $PICO_SDK_VERSION https://github.com/raspberrypi/pico-sdk.git && \
    cd pico-sdk && \
    git submodule update --init

ENV PICO_SDK_PATH="${PICO_PATH}/pico-sdk"

# Get Raspberry Pi Pico examples and configure cmake
RUN git clone --depth 1 --branch "sdk-${PICO_SDK_VERSION}" https://github.com/raspberrypi/pico-examples.git && \
    cd pico-examples && \
    mkdir build && \
    cd build && \
    cmake ..

# Build OpenOCD with Picoprobe support
RUN apt-get update && apt-get -y install --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    libftdi-dev \
    libtool \
    libusb-1.0-0-dev \
    pkg-config \
    texinfo

RUN git clone https://github.com/raspberrypi/openocd.git --branch rp2040 --depth=1 && \
    cd openocd && \
    ./bootstrap && \
    ./configure && \
    make -j4 && \
    sudo make install

# Install minicom for UART communication with Pico
RUN apt-get update && apt-get -y install --no-install-recommends \
    minicom

# Fix warnings from Cortex-Debug extension
# (See https://forums.raspberrypi.com/viewtopic.php?t=333146)
RUN apt-get update && apt-get -y install --no-install-recommends \
    binutils-multiarch && \
    cd /usr/bin && \
    ln -s /usr/bin/objdump objdump-multiarch && \
    ln -s /usr/bin/nm nm-multiarch

# Required by VS Code "xaver.clang-format" extension
RUN apt-get update && apt-get -y install --no-install-recommends \
    clang-format

# Tools for building / verifying RTL
RUN apt-get update && apt-get -y install --no-install-recommends \
    iverilog
