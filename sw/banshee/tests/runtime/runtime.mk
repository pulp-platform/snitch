# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Toolchain location
LLVM_TC_DIR          ?= $(shell readlink -f ~huettern/.local/riscv-llvm-nightly)
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

# Common flags
RISCV_LLVM_FLAGS   = -Wall -mcpu=snitch -g -mno-relax -static
RISCV_LLVM_FLAGS  += -mllvm -enable-misched=false
# RISCV_LLVM_FLAGS    += -mllvm -ssr-noregmerge
# RISCV_LLVM_FLAGS    += -mllvm -snitch-frep-inference
# RISCV_LLVM_FLAGS    += -mllvm -debug-only=snitch-freploops
# RISCV_LLVM_FLAGS    += -Xclang -disable-O0-optnone

RISCV_LLVM_CFLAGS = -std=gnu99 -mcmodel=medany -ffast-math -fno-common
RISCV_LLVM_CFLAGS = -fno-builtin-printf -fdata-sections -ffunction-sections


# Command flags
RISCV_LLVM_CCFLAGS       = $(RISCV_LLVM_FLAGS) $(RISCV_LLVM_CFLAGS) $(LLVM_INCLUDE) -O$(LLVM_OPT)
RISCV_LLVM_ASMFLAGS      = $(RISCV_LLVM_FLAGS) $(LLVM_INCLUDE) -O$(LLVM_OPT)
RISCV_LLVM_CXXFLAGS      = -std=c++20 $(RISCV_LLVM_CFLAGS) $(LLVM_INCLUDE) -O$(LLVM_OPT)
RISCV_LLVM_CPPFLAGS      = -std=c++20 $(RISCV_LLVM_CFLAGS) $(LLVM_INCLUDE) -O$(LLVM_OPT)
RISCV_LLVM_LDFLAGS       = -Wl,--gc-sections -Wl,--no-relax -nostartfiles -fuse-ld=lld -static -lm
RISCV_LLVM_OBJDUMP_FLAGS = --mcpu=snitch --debug-vars
RISCV_LLVM_STRIP_FLAGS   = -g -S -d --strip-unneeded


# RISCV_XLEN    ?= 32
# RISCV_ABI     ?= rv$(RISCV_XLEN)imafd
# RISCV_PREFIX  ?= riscv$(RISCV_XLEN)-unknown-elf-
# RISCV_CC      ?= $(RISCV_PREFIX)gcc
# RISCV_CXX     ?= $(RISCV_PREFIX)g++
# RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump
# RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy
# RISCV_AS      ?= $(RISCV_PREFIX)as
# RISCV_AR      ?= $(RISCV_PREFIX)ar
# RISCV_LD      ?= $(RISCV_PREFIX)ld
# RISCV_STRIP   ?= $(RISCV_PREFIX)strip

# RISCV_FLAGS    ?= -march=$(RISCV_ABI) -mno-fdiv -mcmodel=medany -static -g -std=gnu99 -O3 -ffast-math -fno-common -fno-builtin-printf -Iruntime -DITERATIONS=10
# RISCV_CCFLAGS  ?= $(RISCV_FLAGS)
# RISCV_CXXFLAGS ?= $(RISCV_FLAGS)
# RISCV_LDFLAGS  ?= -static -nostartfiles -lm -lgcc $(RISCV_FLAGS)

# PYTHON ?= python3

# RUNTIME ?= runtime/crt0.S.o runtime/printf.c.o runtime/string.c.o runtime/serial.c.o
# HDR ?=  runtime/runtime.h runtime/libsdma.h

# %.S.o: %.S
# 	$(RISCV_CC) -Iinclude $(RISCV_CCFLAGS) -c $< -o $@

# %.c.o: %.c
# 	$(RISCV_CC) -Iinclude $(RISCV_CCFLAGS) -c $< -o $@

# %.cpp.o: %.cpp
# 	$(RISCV_CXX) $(RISCV_CXXFLAGS) -c $< -o $@
