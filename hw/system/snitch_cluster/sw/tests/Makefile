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
SRC_DIR     := $(abspath $(MK_DIR)/../../../../../sw/tests)
ifeq ($(SELECT_RUNTIME), banshee)
RUNTIME_DIR := $(abspath $(MK_DIR)/../banshee-runtime)
else
RUNTIME_DIR := $(abspath $(MK_DIR)/../rtl-runtime)
endif

# Dependencies
INCDIRS += $(RUNTIME_DIR)/src
INCDIRS += $(RUNTIME_DIR)/../platform-headers
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/api/omp
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/src/omp
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes

# Linker script
LDFLAGS += -L$(abspath $(RUNTIME_DIR))
LDFLAGS += -T$(abspath $(SNRT_DIR)/base.ld)
# Link snRuntime library
LDFLAGS += -L$(abspath $(RUNTIME_DIR)/build/)
LDFLAGS += -lsnRuntime

###########
# Outputs #
###########

# Treat lines starting with '#' as comments
APPS  = $(shell grep -v '^\#' passing-apps.list)
APPS += $(shell grep -v '^\#' failing-apps.list)
APPS += $(shell grep -v '^\#' banshee-apps.list)

ELFS        = $(abspath $(addprefix $(BUILDDIR)/,$(addsuffix .elf,$(APPS))))
DEPS        = $(abspath $(addprefix $(BUILDDIR)/,$(addsuffix .d,$(APPS))))
DUMPS       = $(abspath $(addprefix $(BUILDDIR)/,$(addsuffix .dump,$(APPS))))
DWARFS      = $(abspath $(addprefix $(BUILDDIR)/,$(addsuffix .dwarf,$(APPS))))
ALL_OUTPUTS = $(ELFS)

ifeq ($(DEBUG), ON)
ALL_OUTPUTS += $(DUMPS) $(DWARFS)
endif

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

$(BUILDDIR)/%.d: $(SRC_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -MM -MT '$(BUILDDIR)/$*.elf' $< > $@

$(BUILDDIR)/%.elf: $(SRC_DIR)/%.c $(BUILDDIR)/%.d | $(BUILDDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRC_DIR)/$*.c -o $@

$(BUILDDIR)/%.dump: $(BUILDDIR)/%.elf | $(BUILDDIR)
	$(OBJDUMP) -D -S $< > $@

$(BUILDDIR)/%.dwarf: $(BUILDDIR)/%.elf | $(BUILDDIR)
# 	$(READELF) --debug-dump $< > $@
	$(DWARFDUMP) --all $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif
