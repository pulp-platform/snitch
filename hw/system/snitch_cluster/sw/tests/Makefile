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

# Treat lines starting with '#' as comments
define get_apps_from_list
	$(shell grep -v '^\#' $(1))
endef

ifeq ($(SELECT_RUNTIME), banshee)
	APPS = $(call get_apps_from_list,banshee-apps.list)
else
	APPS  = $(call get_apps_from_list,passing-apps.list)
	APPS += $(call get_apps_from_list,failing-apps.list)
endif

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
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(BUILDDIR)/$*.elf' $< > $@

$(BUILDDIR)/%.elf: $(SRC_DIR)/%.c $(BUILDDIR)/%.d | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) $(SRC_DIR)/$*.c -o $@

$(BUILDDIR)/%.dump: $(BUILDDIR)/%.elf | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D -S $< > $@

$(BUILDDIR)/%.dwarf: $(BUILDDIR)/%.elf | $(BUILDDIR)
# 	$(RISCV_READELF) --debug-dump $< > $@
	$(RISCV_DWARFDUMP) --all $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif
