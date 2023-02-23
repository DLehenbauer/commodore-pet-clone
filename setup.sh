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

git clean -Xfd

mkdir build
pushd build

# Use 'RelWithDebInfo' instead of 'Debug' or TINY_USB will panic due to missed timing deadlines
# Use '-DPICO_COPY_TO_RAM=1' or PicoDVI will not produce a display, but this disables breakpoints
cmake -DPICO_COPY_TO_RAM=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo "$@" ..

popd

# CMake configuration will populate 'build/roms'.  Now run './roms.sh' to generate *.h files.
pushd fw/roms
./roms.sh
popd
