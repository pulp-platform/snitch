#!/usr/bin/env bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

root=$1

cd $root
git clone git@github.com:riscv-collab/riscv-gnu-toolchain.git riscv-gnu-toolchain --depth=1 --recurse-submodules
mkdir tc-hrv-obare
cd riscv-gnu-toolchain
./configure --prefix=$root/tc-hrv-obare
make -j`nproc`
cd ..
