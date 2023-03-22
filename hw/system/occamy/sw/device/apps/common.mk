# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

include ../../toolchain.mk

###################
# Build variables #
###################

# Directories
BUILDDIR    = $(abspath build)
APPSDIR     = $(abspath ../)
RUNTIME_DIR = $(abspath ../../runtime)
SNRT_DIR    = $(abspath ../../../../../../../sw/snRuntime)
SW_DIR      = $(abspath ../../../)

# Dependencies
INCDIRS += $(RUNTIME_DIR)/src
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes
INCDIRS += $(SW_DIR)/shared/platform/generated
INCDIRS += $(SW_DIR)/shared/platform
INCDIRS += $(SW_DIR)/shared/runtime

# Linking sources
BASE_LD       = $(abspath $(SNRT_DIR)/base.ld)
MEMORY_LD     = $(abspath $(APPSDIR)/memory.ld)
ORIGIN_LD     = $(abspath $(BUILDDIR)/origin.ld)
BASE_LD       = $(abspath $(SNRT_DIR)/base.ld)
SNRT_LIB_DIR  = $(abspath $(RUNTIME_DIR)/build/)
SNRT_LIB_NAME = snRuntime
SNRT_LIB      = $(realpath $(SNRT_LIB_DIR)/lib$(SNRT_LIB_NAME).a)
LD_SRCS       = $(BASE_LD) $(MEMORY_LD) $(ORIGIN_LD) $(SNRT_LIB)

# Linker flags
LDFLAGS += -nostartfiles
LDFLAGS += -lm
LDFLAGS += -lgcc
# Linker script
LDFLAGS += -L$(APPSDIR)
LDFLAGS += -L$(BUILDDIR)
LDFLAGS += -T$(BASE_LD)
# Link snRuntime library
LDFLAGS += -L$(SNRT_LIB_DIR)
LDFLAGS += -l$(SNRT_LIB_NAME)

# Objcopy flags
OBJCOPY_FLAGS  = -O binary
OBJCOPY_FLAGS += --remove-section=.comment
OBJCOPY_FLAGS += --remove-section=.riscv.attributes
OBJCOPY_FLAGS += --remove-section=.debug_info
OBJCOPY_FLAGS += --remove-section=.debug_abbrev
OBJCOPY_FLAGS += --remove-section=.debug_line
OBJCOPY_FLAGS += --remove-section=.debug_str
OBJCOPY_FLAGS += --remove-section=.debug_aranges

###########
# Outputs #
###########

ELF         = $(abspath $(BUILDDIR)/$(APP).elf)
DEP         = $(abspath $(BUILDDIR)/$(APP).d)
BIN         = $(abspath $(BUILDDIR)/$(APP).bin)
DUMP        = $(abspath $(BUILDDIR)/$(APP).dump)
DWARF       = $(abspath $(BUILDDIR)/$(APP).dwarf)
ALL_OUTPUTS = $(BIN) $(DUMP) $(DWARF)

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
	$(CC) $(CFLAGS) -MM -MT '$(ELF)' $< > $@

$(ELF): $(DEP) $(LD_SRCS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRCS) -o $@

$(BIN): $(ELF) | $(BUILDDIR)
	$(OBJCOPY) $(OBJCOPY_FLAGS) $< $@

$(DUMP): $(ELF) | $(BUILDDIR)
	$(OBJDUMP) -D $< > $@

$(DWARF): $(ELF) | $(BUILDDIR)
	$(READELF) --debug-dump $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEP)
endif
