# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/main/containers/debian

# [Choice] Debian version (use bullseye or stretch on local arm64/Apple Silicon): bullseye, buster, stretch
ARG VARIANT="bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && apt-get -y install --no-install-recommends \
    debootstrap \
    qemu-user-static

# [Choice] Raspberry Pi OS version: bullseye, buster
ARG RPI_RELEASE="bullseye"
ARG RPI_SYSROOT=/opt/rpi/sysroot
RUN wget -qO - http://raspbian.raspberrypi.org/raspbian.public.key | sudo apt-key add -
RUN qemu-debootstrap --no-check-gpg --arch=armhf --variant=buildd $RPI_RELEASE $RPI_SYSROOT http://raspbian.raspberrypi.org/raspbian/

RUN echo "deb http://raspbian.raspberrypi.org/raspbian/ $RPI_RELEASE main contrib non-free rpi" | sudo tee /opt/rpi/sysroot/etc/apt/sources.list
RUN echo "deb http://archive.raspberrypi.org/debian/ $RPI_RELEASE main" | sudo tee /opt/rpi/sysroot/etc/apt/sources.list.d/raspi.list
RUN wget -P /tmp http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
RUN mv /tmp/raspberrypi.gpg.key $RPI_SYSROOT/tmp

RUN chroot $RPI_SYSROOT apt-key add /tmp/raspberrypi.gpg.key
RUN chroot $RPI_SYSROOT apt-get update && chroot $RPI_SYSROOT apt-get -y install --no-install-recommends \
    libboost1.74-all-dev \
    libraspberrypi-dev \
    libsdl2-dev \
    raspberrypi-kernel-headers \
    symlinks

# The absolute symlinks created while chroot'ed will fail to resolve when using cross-compilers
# from outside the chroot environment.  Fix this by converting these to relative links that will
# work in both environments.
RUN chroot $RPI_SYSROOT symlinks -rc .

# Toolchain for cross-compiling
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    cmake \
    crossbuild-essential-arm64 \
    crossbuild-essential-armhf \
    gdb-multiarch \
    pkg-config

# Required by VS Code "xaver.clang-format" extension
RUN apt-get update && apt-get -y install --no-install-recommends \
    clang-format

# Tools for building / verifying RTL
RUN apt-get update && apt-get -y install --no-install-recommends \
    iverilog

# Raspberry Pi Pico SDK
ARG PICO_PATH="/opt/pico"
WORKDIR $PICO_PATH

# Install cross toolchain for Raspberry Pi Pico.  Note that we also need native
# the native toolchain in order to build the 'pioasm' and 'elf2uf2' tools.
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    cmake \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib

# Get latest Raspberry Pi Pico SDK
RUN git clone -b master https://github.com/raspberrypi/pico-sdk.git && \
    cd pico-sdk && \
    git submodule update --init

ENV PICO_SDK_PATH="${PICO_PATH}/pico-sdk"

# Get and build latest Raspberry Pi Pico examples
RUN git clone -b master https://github.com/raspberrypi/pico-examples.git && \
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

RUN git clone https://github.com/raspberrypi/openocd.git --branch rp2040 --depth=1 --no-single-branch && \
    cd openocd && \
    ./bootstrap && \
    ./configure --enable-picoprobe && \
    make -j4 && \
    sudo make install

# Install minicom for UART communication with Pico
RUN apt-get update && apt-get -y install --no-install-recommends \
    minicom
