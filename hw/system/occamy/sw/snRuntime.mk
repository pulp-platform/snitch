# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

DEBUG ?= OFF # ON to add debugging symbols to snRuntime
SN_RUNTIME_PATH = $(abspath ../../../../sw/snRuntime)
SN_RUNTIME_BUILD_DIR = $(SN_RUNTIME_PATH)/build

$(SN_RUNTIME_BUILD_DIR)/libsnRuntime-cluster.a: | $(SN_RUNTIME_BUILD_DIR)
	cd $(SN_RUNTIME_BUILD_DIR) && make

$(SN_RUNTIME_BUILD_DIR):
	cd $(SN_RUNTIME_PATH) && mkdir build && \
	cd build && cmake -DDEBUG=$(DEBUG) -DSNITCH_RUNTIME=snRuntime-cluster ..

.PHONY: clean update-lib

update-lib: | $(SN_RUNTIME_BUILD_DIR)
	cd $(SN_RUNTIME_BUILD_DIR) && make

clean:
	rm -rf $(SN_RUNTIME_BUILD_DIR)