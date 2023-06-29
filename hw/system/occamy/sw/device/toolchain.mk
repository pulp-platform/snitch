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
# RISCV_CC      = riscv32-unknown-elf-gcc
# RISCV_AR      = riscv32-unknown-elf-ar
# RISCV_OBJCOPY = riscv32-unknown-elf-objcopy
# RISCV_OBJDUMP = riscv32-unknown-elf-objdump
# RISCV_READELF = riscv32-unknown-elf-readelf
RISCV_CC        ?= clang
RISCV_LD        ?= lld
RISCV_AR        ?= llvm-ar
RISCV_OBJCOPY   ?= llvm-objcopy
RISCV_OBJDUMP   ?= llvm-objdump
RISCV_DWARFDUMP ?= llvm-dwarfdump

# Compiler flags
RISCV_CFLAGS += $(addprefix -I,$(INCDIRS))
ifeq ($(RISCV_CC), clang)
RISCV_CFLAGS += -mcpu=snitch
else 
RISCV_CFLAGS += -march=rv32imafd
endif
RISCV_CFLAGS += -mabi=ilp32d
RISCV_CFLAGS += -mcmodel=medany
# RISCV_CFLAGS += -mno-fdiv
RISCV_CFLAGS += -ffast-math
RISCV_CFLAGS += -fno-builtin-printf
RISCV_CFLAGS += -fno-common
RISCV_CFLAGS += -menable-experimental-extensions
RISCV_CFLAGS += -fopenmp
RISCV_CFLAGS += -O3
ifeq ($(DEBUG), ON)
RISCV_CFLAGS += -g
endif

# Linker flags
RISCV_LDFLAGS += -fuse-ld=$(RISCV_LD)
RISCV_LDFLAGS += -nostartfiles
RISCV_LDFLAGS += -lm

# Archiver flags
RISCV_ARFLAGS = rcs
