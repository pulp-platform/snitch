# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Tim Fischer <fischeti@iis.ee.ethz.ch>

BLAS_DIR = $(abspath ../../../../../../../sw/blas)
APPS_DIR = $(abspath ../..)

include $(BLAS_DIR)/gemm/Makefile
include $(APPS_DIR)/common.mk

$(DEP): $(DATA_DIR)/data.h
