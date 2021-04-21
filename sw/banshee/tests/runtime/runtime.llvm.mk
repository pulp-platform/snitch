# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Toolchain location
LLVM_TC_DIR          ?= $(shell readlink -f ~sem21f15/.local/riscv-llvm-nightly)
LLVM_TC_PREFIX       = $(LLVM_TC_DIR)/bin
LLVM_TC_SYSROOT      = $(LLVM_TC_DIR)/riscv32-snitch-elf
LLVM_COMPILER_RT     = $(LLVM_TC_DIR)/lib/linux

# User flags
LLVM_INCLUDE     = -Iruntime
LLVM_OPT         ?= 3

# Commands
RISCV_LLVM_CC        = $(LLVM_TC_PREFIX)/clang
RISCV_LLVM_ASM       = $(LLVM_TC_PREFIX)/clang
RISCV_LLVM_LD        = $(LLVM_TC_PREFIX)/clang
RISCV_LLVM_OBJDUMP   = $(LLVM_TC_PREFIX)/llvm-objdump
RISCV_LLVM_STRIP     = $(LLVM_TC_PREFIX)/llvm-strip
RISCV_LLVM_SIZE      = $(LLVM_TC_PREFIX)/llvm-size

# Common CFLAGS
RISCV_LLVM_CFLAGS    = -Wall -mcpu=snitch -mcmodel=medany -ffast-math -fno-common -fno-builtin-printf --sysroot=$(LLVM_TC_SYSROOT)
RISCV_LLVM_CFLAGS    += -g -Wno-main -mno-relax -static -fdata-sections -ffunction-sections
# RISCV_LLVM_CFLAGS    += -mllvm -enable-misched=false
# RISCV_LLVM_CFLAGS    += -mllvm -ssr-noregmerge
# RISCV_LLVM_CFLAGS    += -mllvm -snitch-frep-inference
# RISCV_LLVM_CFLAGS    += -mllvm -debug-only=snitch-freploops
# RISCV_LLVM_CFLAGS    += -Xclang -disable-O0-optnone

# Command flags
RISCV_LLVM_CCFLAGS       = -std=gnu99 $(RISCV_LLVM_CFLAGS) $(LLVM_CFLAGS) $(LLVM_INCLUDE) -O$(LLVM_OPT)
RISCV_LLVM_ASMFLAGS      = -std=gnu99 $(RISCV_LLVM_CFLAGS) $(LLVM_CFLAGS) $(LLVM_INCLUDE) -O$(LLVM_OPT)
RISCV_LLVM_CXXFLAGS      = -std=c++20 $(RISCV_LLVM_CFLAGS) $(LLVM_CFLAGS) $(LLVM_INCLUDE) -O$(LLVM_OPT)
RISCV_LLVM_CPPFLAGS      = -std=c++20 $(RISCV_LLVM_CFLAGS) $(LLVM_CFLAGS) $(LLVM_INCLUDE) -O$(LLVM_OPT)
RISCV_LLVM_LDFLAGS       = -Wl,--gc-sections -Wl,--no-relax -fuse-ld=lld -static -lm -L$(LLVM_TC_SYSROOT)/lib -L$(LLVM_COMPILER_RT)
RISCV_LLVM_OBJDUMP_FLAGS = --mcpu=snitch --debug-vars
RISCV_LLVM_STRIP_FLAGS   = -g -S -d --strip-unneeded
