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
BUILDDIR    = $(abspath build/)
RUNTIME_DIR = $(abspath ../)
SRC_DIR     = $(abspath $(RUNTIME_DIR)/rtl/src)
SNRT_DIR    = $(abspath $(RUNTIME_DIR)/../../../../../sw/snRuntime)

# Dependencies
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/src/omp
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/api/omp
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes
INCDIRS += $(RUNTIME_DIR)/shared
SRCS += $(SRC_DIR)/snitch_cluster_start.S
SRCS += $(SRC_DIR)/snrt.c

###########
# Outputs #
###########

OBJS        = $(addprefix $(BUILDDIR)/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))
DEPS        = $(addprefix $(BUILDDIR)/,$(addsuffix .d,$(basename $(notdir $(SRCS)))))
LIB         = $(BUILDDIR)/libsnRuntime.a
DUMP        = $(BUILDDIR)/libsnRuntime.dump
ALL_OUTPUTS = $(LIB) $(DUMP)

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

$(BUILDDIR)/%.o: $(SRC_DIR)/%.S | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: $(SRC_DIR)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -c $< -o $@

$(BUILDDIR)/%.d: $(SRC_DIR)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(@:.d=.o)' $< > $@

$(LIB): $(OBJS) | $(BUILDDIR)
	$(RISCV_AR) $(RISCV_ARFLAGS) $@ $^

$(DUMP): $(LIB) | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif
