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
BUILDDIR    = $(abspath build/)
SW_DIR      = $(abspath ../)
RUNTIME_DIR = $(abspath $(SW_DIR)/runtime)
SRC_DIR     = $(abspath $(RUNTIME_DIR)/src)
SNRT_DIR    = $(abspath $(SW_DIR)/../../../../sw/snRuntime)

# Dependencies
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(RUNTIME_DIR)/platform
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
