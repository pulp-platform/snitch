# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Gianna Paulin <pauling@iis.ee.ethz.ch>

# DNN_DIR = $(abspath ../../../../../../../sw/snDNN)
DNN_DIR = $(abspath ..)
# SNDNN_DIR = $(abspath ..)
APPS_DIR = $(abspath ../..)

APP_NAME = fusedconv
USE_SNDNN_LIBRARY = true

include $(DNN_DIR)/Makefile
include $(APPS_DIR)/common.mk

$(DEP): $(DATA_DIR)/data_$(APP_NAME).h
