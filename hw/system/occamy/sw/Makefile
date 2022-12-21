# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

DEBUG ?= OFF # ON to add debugging symbols to Snitch binaries

# Flags can be passed to CMake on the command line through the
# following parameter, example uses:
# -DSIM_WITH_HBM     : use HBM instead of simulation memory
# -DSELECT_FLL={0,1} : use either ETH (0) or GF (1) FLL
CMAKE_C_FLAGS ?=

all: tests

.PHONY: clean tests

clean:
	rm -rf build

build:
	mkdir -p build
	cd build && cmake -DDEBUG=$(DEBUG) -DCMAKE_C_FLAGS="$(CMAKE_C_FLAGS)" .. && cd -

tests: | build
	make -C build clean all
