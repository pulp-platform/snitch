# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include this Makefile
MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

APP  := lto
SRCS := $(addprefix $(MK_DIR),lto.c lto_a.c)
