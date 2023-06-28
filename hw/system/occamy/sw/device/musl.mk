# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Viviane Potocnik <vivianep@iis.ee.ethz.ch>

######################
# Invocation options #
######################

DEBUG ?= OFF # ON to turn on debugging symbols

###################
# Build variables #
###################

# Compiler toolchain
RISCV_CC        ?= riscv32-unknown-elf-clang
RISCV_CXX 	    ?= riscv32-unknown-elf-clang++
RISCV_LD        ?= lld
RISCV_AR        ?= llvm-ar
RISCV_STRIP     ?= llvm-strip
RISCV_RANLIB	?= llvm-ranlib
RISCV_OBJCOPY   ?= llvm-objcopy
RISCV_OBJDUMP   ?= llvm-objdump
RISCV_DWARFDUMP ?= llvm-dwarfdump
SW_INSTALL_DIR  ?= /scratch/vivianep/snitch_dev/snitch/sw/vendor/install/

# Compiler flags
RISCV_CFLAGS += $(addprefix -I,$(INCDIRS))
RISCV_CFLAGS += -mcpu=snitch
RISCV_CFLAGS += -menable-experimental-extensions
RISCV_CFLAGS += -mabi=ilp32d
RISCV_CFLAGS += -mcmodel=medany
RISCV_CFLAGS += -ffast-math
RISCV_CFLAGS += -fno-builtin-printf
RISCV_CFLAGS += -fno-common
RISCV_CFLAGS += -fopenmp
RISCV_CFLAGS += -flto=thin
RISCV_CFLAGS += -ffunction-sections
RISCV_CFLAGS += -Wextra
RISCV_CFLAGS += -static
RISCV_CFLAGS += -mllvm -enable-misched=false
RISCV_CFLAGS += -mno-relax
# musl specific flags
RISCV_CFLAGS += -menable-experimental-extensions
RISCV_CFLAGS += -I$(SW_INSTALL_DIR)include
RISCV_CFLAGS += -B$(SW_INSTALL_DIR)bin
# RISCV_CFLAGS += -static-libgcc
RISCV_CFLAGS += -nostdinc
RISCV_CFLAGS += -ftls-model=local-exec

RISCV_CFLAGS += -O3
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
RISCV_LDFLAGS += -L$(SW_INSTALL_DIR)lib
RISCV_LDFLAGS += -nostdinc
RISCV_LDFLAGS += -flto=thin
# RISCV_LDFLAGS += -static-libgcc


# Archiver flags
RISCV_ARFLAGS = rcs
