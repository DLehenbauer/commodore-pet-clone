# Git

## Fix broken submodule

1. Remove from .git/config
2. Remove from .gitmodules

```sh
rm -rf fw/external/no-OS-FatFS-SD-SPI-RPi-Pico
git rm --cached fw/external/no-OS-FatFS-SD-SPI-RPi-Pico
rm -rf .git/modules/fw/external/no-OS-FatFS-SD-SPI-RPi-Pico
```

Alternate:
```sh
git submodule deinit -f ./fw/external/no-OS-FatFS-SD-SPI-RPi-Pico
```

## Setup submodule at tag

```sh
pushd fw/external
git submodule add https://github.com/carlk3/no-OS-FatFS-SD-SPI-RPi-Pico.git
pushd no-OS-FatFS-SD-SPI-RPi-Pico
git fetch --tags
git checkout tags/v1.0.8
popd
git add no-OS-FatFS-SD-SPI-RPi-Pico
git commit -m "Move 'no-OS-FatFS-SD-SPI-RPi-Pico' to tags/v1.0.8"
popd
```
