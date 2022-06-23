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

git clean -Xfd
mkdir sw/build
cd sw/build
cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/cross-rpi0w2.cmake -DCMAKE_BUILD_TYPE=Debug "$@" ../..
