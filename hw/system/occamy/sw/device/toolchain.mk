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
CC      = riscv32-unknown-elf-gcc
AR      = riscv32-unknown-elf-ar
OBJCOPY = riscv32-unknown-elf-objcopy
OBJDUMP = riscv32-unknown-elf-objdump
READELF = riscv32-unknown-elf-readelf

# Compiler flags
CFLAGS += $(addprefix -I,$(INCDIRS))
CFLAGS += -march=rv32imafd
CFLAGS += -mabi=ilp32d
CFLAGS += -mcmodel=medany
CFLAGS += -mno-fdiv
CFLAGS += -ffast-math
CFLAGS += -fno-builtin-printf
CFLAGS += -fno-common
CFLAGS += -O3
ifeq ($(DEBUG), ON)
CFLAGS += -g
endif

# Archiver flags
ARFLAGS = rcs
