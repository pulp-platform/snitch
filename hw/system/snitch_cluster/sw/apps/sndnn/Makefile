# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Gianna Paulin <pauling@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include this Makefile
MK_DIR        := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
DATA_DIR      := $(realpath $(MK_DIR)/data)
SRC_DIR       := $(realpath $(MK_DIR)/$(APP_NAME)/src)
SNDNN_SRC_DIR := $(realpath $(MK_DIR)../../../../../sw/snDNN/src)

INCLUDE_DIR := $(realpath $(SNDNN_SRC_DIR)/../include)

DATA_CFG ?= $(DATA_DIR)/$(APP_NAME)_params.hjson

APP     ?= $(APP_NAME)
SRCS    ?= $(realpath $(SRC_DIR)/net_$(APP_NAME).c)
INCDIRS += $(DATA_DIR) $(SRC_DIR) $(INCLUDE_DIR)

$(DATA_DIR)/data_$(APP_NAME).h: $(MK_DIR)/datagen.py $(DATA_CFG)
	$< -c $(DATA_CFG) > $@

.PHONY: clean-data clean

clean-data:
	rm -f $(DATA_DIR)/data_$(APP_NAME).h

clean: clean-data
