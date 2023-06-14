# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include
# this Makefile from multiple different locations
MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
include $(MK_DIR)/../toolchain.mk

###################
# Build variables #
###################

# Directories
BUILDDIR     = $(abspath build)
SNRT_DIR    := $(abspath $(MK_DIR)/../../../../../sw/snRuntime)
ifeq (SELECT_RUNTIME, banshee)
RUNTIME_DIR := $(abspath $(MK_DIR)/../runtime/banshee)
else
RUNTIME_DIR := $(abspath $(MK_DIR)/../runtime/rtl)
endif

# Dependencies
INCDIRS += $(RUNTIME_DIR)/src
INCDIRS += $(RUNTIME_DIR)/../shared
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/api/omp
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/src/omp
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes

# Linker script
RISCV_LDFLAGS += -L$(abspath $(RUNTIME_DIR))
RISCV_LDFLAGS += -T$(abspath $(SNRT_DIR)/base.ld)
# Link snRuntime library
RISCV_LDFLAGS += -L$(abspath $(RUNTIME_DIR)/build/)
RISCV_LDFLAGS += -lsnRuntime

###########
# Outputs #
###########

ELF         = $(abspath $(addprefix $(BUILDDIR)/,$(addsuffix .elf,$(APP))))
DEP         = $(abspath $(addprefix $(BUILDDIR)/,$(addsuffix .d,$(APP))))
DUMP        = $(abspath $(addprefix $(BUILDDIR)/,$(addsuffix .dump,$(APP))))
DWARF       = $(abspath $(addprefix $(BUILDDIR)/,$(addsuffix .dwarf,$(APP))))
ALL_OUTPUTS = $(ELF) $(DEP) $(DUMP) $(DWARF)

#########
# Rules #
#########

.PHONY: all
all: $(ALL_OUTPUTS)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)

$(BUILDDIR):
	mkdir -p $@

$(DEP): $(SRCS) | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(ELF)' $< > $@

$(ELF): $(SRCS) | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) $(SRCS) -o $@

$(DUMP): $(ELF) | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D $< > $@

$(DWARF): $(ELF) | $(BUILDDIR)
# 	$(RISCV_READELF) --debug-dump $< > $@
	$(RISCV_DWARFDUMP) $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEP)
endif
