# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

######################
# Invocation options #
######################

DEBUG ?= OFF # ON to turn on debugging symbols

###################
# Build variables #
###################

# Compiler toolchain
CC        ?= clang
LD        ?= lld
AR        ?= llvm-ar
OBJCOPY   ?= llvm-objcopy
OBJDUMP   ?= llvm-objdump
DWARFDUMP ?= llvm-dwarfdump

# Compiler flags
CFLAGS += $(addprefix -I,$(INCDIRS))
CFLAGS += -mcpu=snitch
CFLAGS += -menable-experimental-extensions
CFLAGS += -mabi=ilp32d
CFLAGS += -mcmodel=medany
CFLAGS += -ffast-math
CFLAGS += -fno-builtin-printf
CFLAGS += -fno-common
CFLAGS += -fopenmp
CFLAGS += -O3
ifeq ($(DEBUG), ON)
CFLAGS += -g
endif

# Linker flags
LDFLAGS += -fuse-ld=$(LD)
LDFLAGS += -nostartfiles
LDFLAGS += -lm

# Archiver flags
ARFLAGS = rcs
