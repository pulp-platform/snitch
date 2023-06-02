# musl Guide

In this guide, we show you how to set up `Snitch` with the `musl` library. 

## Prerequisites
Make sure that you update this `musl` submodule to the latest version. 
```
git submodule update --init --recursive
```
Afterward, we need to set the correct compiler so that `Snitch` can compile the `musl` library. 
```
export CC=clang
```
Where `clang` is the compiler that you want to use. At IIS, please use `/usr/pack/riscv-1.0-kgf/pulp-llvm-0.12.0/bin/riscv32-unknown-elf-clang`.
Next, we create the installation directory and configure the build and installation process. 
```
mkdir /snitch/sw/vendor/install
./configure --disable-shared --prefix=/snitch/sw/vendor/install/ --with-boost-libdir=<path_to_boost_dir> --enable-wrapper=all CFLAGS="-mcpu=snitch -menable-experimental-extensions"
```
Where `<path_to_boost_dir>` is the path to the `boost` library. At IIS, if you are using Alma Linux you might have to install the `boost-devel` package. 
You can do this by retrieviing the `rpm` package and updating your `LD_LIBRARY_PATH` variable. 
```
wget https://repo.almalinux.org/almalinux/8/AppStream/aarch64/os/Packages/boost-regex-1.66.0-13.el8.aarch64.rpm
rpm2cpio boost-regex-1.66.0-13.el8.aarch64.rpm | cpio -idmv
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib64
```
Afterward, we can build and install the `musl` library. 
```
make -j$(nproc)
make install
```
Finally, we need to set the `LD_LIBRARY_PATH` variable so that `Snitch` can find the `musl` library. 
```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/snitch/sw/vendor/install/lib
```

** Important ** : Whenever you change the source code of the `musl` library, you need to recompile it. 


