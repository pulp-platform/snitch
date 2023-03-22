# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

include ../toolchain.mk

###################
# Build variables #
###################

# Directories
BUILDDIR = $(abspath build/)
SRC_DIR  = $(abspath src/)
SW_DIR   = $(abspath ../../)
SNRT_DIR = $(abspath ../../../../../../sw/snRuntime)

# Dependencies
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes
INCDIRS += $(SW_DIR)/shared/platform
INCDIRS += $(SW_DIR)/shared/platform/generated
INCDIRS += $(SW_DIR)/shared/runtime
SRCS += $(SRC_DIR)/occamy_start.S
SRCS += $(SRC_DIR)/snrt.c

###########
# Outputs #
###########

OBJS        = $(addprefix $(BUILDDIR)/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))
DEPS        = $(addprefix $(BUILDDIR)/,$(addsuffix .d,$(basename $(notdir $(SRCS)))))
LIB         = $(BUILDDIR)/libsnRuntime.a
DUMP        = $(BUILDDIR)/libsnRuntime.dump
ALL_OUTPUTS = $(DEPS) $(LIB) $(DUMP)

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
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: $(SRC_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR)/%.d: $(SRC_DIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -MM -MT '$(@:.d=.o)' $< > $@

$(LIB): $(OBJS) | $(BUILDDIR)
	$(AR) $(ARFLAGS) $@ $^

$(DUMP): $(LIB) | $(BUILDDIR)
	$(OBJDUMP) -D $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif
