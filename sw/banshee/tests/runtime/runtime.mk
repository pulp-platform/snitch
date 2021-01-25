# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

RISCV_XLEN    ?= 32
RISCV_ABI     ?= rv$(RISCV_XLEN)imafd
RISCV_PREFIX  ?= riscv$(RISCV_XLEN)-unknown-elf-
RISCV_CC      ?= $(RISCV_PREFIX)gcc
RISCV_CXX     ?= $(RISCV_PREFIX)g++
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump
RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy
RISCV_AS      ?= $(RISCV_PREFIX)as
RISCV_AR      ?= $(RISCV_PREFIX)ar
RISCV_LD      ?= $(RISCV_PREFIX)ld
RISCV_STRIP   ?= $(RISCV_PREFIX)strip

RISCV_FLAGS    ?= -march=$(RISCV_ABI) -mno-fdiv -mcmodel=medany -static -g -std=gnu99 -O3 -ffast-math -fno-common -fno-builtin-printf -Iruntime -DITERATIONS=10
RISCV_CCFLAGS  ?= $(RISCV_FLAGS)
RISCV_CXXFLAGS ?= $(RISCV_FLAGS)
RISCV_LDFLAGS  ?= -static -nostartfiles -lm -lgcc $(RISCV_FLAGS)

PYTHON ?= python3

RUNTIME ?= runtime/crt0.S.o runtime/printf.c.o runtime/string.c.o runtime/serial.c.o
HDR ?=  runtime/runtime.h runtime/libsdma.h

%.S.o: %.S
	$(RISCV_CC) -Iinclude $(RISCV_CCFLAGS) -c $< -o $@

%.c.o: %.c
	$(RISCV_CC) -Iinclude $(RISCV_CCFLAGS) -c $< -o $@

%.cpp.o: %.cpp
	$(RISCV_CXX) $(RISCV_CXXFLAGS) -c $< -o $@
