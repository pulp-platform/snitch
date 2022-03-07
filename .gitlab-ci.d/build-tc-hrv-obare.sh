#!/usr/bin/env bash

root=$1

cd $root
git clone git@github.com:riscv-collab/riscv-gnu-toolchain.git riscv-gnu-toolchain --depth=1 --recurse-submodules
mkdir tc-hrv-obare
cd riscv-gnu-toolchain
./configure --prefix=$root/tc-hrv-obare
make -j`nproc`
cd ..
