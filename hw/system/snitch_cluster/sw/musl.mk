# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Viviane Potocnik <vivianep@iis.ee.ethz.ch>

######################
# Invocation options #
######################

DEBUG ?= OFF # ON to turn on debugging symbols

# SW_INSTALL_DIR  ?= /scratch/vivianep/snitch_dev/snitch/sw/vendor/install

# Usage of absolute paths is required to externally include
# this Makefile from multiple different locations
MUSL_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SW_INSTALL_DIR  ?= $(abspath $(MUSL_DIR)/../../../../sw/vendor/install/)


###################
# Build variables #
###################

# Compiler toolchain
RISCV_CC        ?= clang
RISCV_CXX 	    ?= clang++
RISCV_LD        ?= lld
RISCV_AR        ?= llvm-ar
RISCV_OBJCOPY   ?= llvm-objcopy
RISCV_OBJDUMP   ?= llvm-objdump
RISCV_DWARFDUMP ?= llvm-dwarfdump
RISCV_RANLIB	?= llvm-ranlib
RISCV_STRIP     ?= llvm-strip

RISCV_CFLAGS += $(addprefix -I,$(INCDIRS))
RISCV_CFLAGS += -mcpu=snitch
RISCV_CFLAGS += -menable-experimental-extensions
RISCV_CFLAGS += -mabi=ilp32d
RISCV_CFLAGS += -mcmodel=medany
RISCV_CFLAGS += -ffast-math
RISCV_CFLAGS += -fno-builtin-printf
RISCV_CFLAGS += -fno-common
RISCV_CFLAGS += -fopenmp
RISCV_CFLAGS += -O3
RISCV_CFLAGS += -flto=thin
RISCV_CFLAGS += -ffunction-sections
RISCV_CFLAGS += -Wextra
RISCV_CFLAGS += -static
RISCV_CFLAGS += -mllvm -enable-misched=false
RISCV_CFLAGS += -mno-relax
RISCV_CFLAGS += -ftls-model=local-exec
# musl specific flags
RISCV_CFLAGS += -I$(SW_INSTALL_DIR)/include
RISCV_CFLAGS += -B$(SW_INSTALL_DIR)/bin
RISCV_CFLAGS += -nostdinc
ifeq ($(DEBUG), ON)
RISCV_CFLAGS += -g
endif

# Linker flags
RISCV_LDFLAGS += -fuse-ld=$(RISCV_LD)
RISCV_LDFLAGS += -nostartfiles
RISCV_LDFLAGS += -lm
RISCV_LDFLAGS += -static
RISCV_LDFLAGS += -mcpu=snitch -nostartfiles -fuse-ld=lld -Wl,--image-base=0x80000000
RISCV_LDFLAGS += -Wl,-z,norelro
RISCV_LDFLAGS += -Wl,--gc-sections
RISCV_LDFLAGS += -Wl,--no-relax
RISCV_LDFLAGS += -Wl,--verbose
# musl specific flags
RISCV_LDFLAGS += -L$(SW_INSTALL_DIR)/lib
RISCV_LDFLAGS += -nostdinc
RISCV_LDFLAGS += -flto=thin

# Archiver flags
RISCV_ARFLAGS = rcs