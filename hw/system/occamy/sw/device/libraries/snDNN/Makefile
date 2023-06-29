# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

ifeq ($(MUSL),1)
include ../../musl.mk
else
include ../../toolchain.mk
endif

###################
# Build variables #
###################


#############
# snRuntime #
#############
# Directories
CUR_DIR     		:= $(abspath .)
SNRT_DIR    		:= $(abspath ../../../../../../../sw/snRuntime)
RUNTIME_DIR 		:= $(abspath ../../runtime)
SHARED_DIR  		:= $(abspath ../../../../sw/shared)
HERO_RUNTIME_DIR 	:= $(abspath ../../../../sw/shared/runtime)
# ifeq (SELECT_RUNTIME, banshee)
# RUNTIME_DIR := $(abspath ../../runtime/banshee)
# else
# RUNTIME_DIR := $(abspath ../../runtime/rtl)
# endif

# Dependencies
INCDIRS += $(RUNTIME_DIR)/src
INCDIRS += $(RUNTIME_DIR)/../shared
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/api/omp
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/src/omp
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes
INCDIRS += $(SHARED_DIR)/platform
INCDIRS += $(SHARED_DIR)/platform/generated
INCDIRS += $(HERO_RUNTIME_DIR)

#########
# snDNN #
#########
# Directories
BUILDDIR      = $(abspath build/)
SNDNN_DIR     = $(abspath ../../../../../../../sw/snDNN)
SRC_DIR       = $(SNDNN_DIR)/src
SRC_DIR_LAYER = $(CUR_DIR)/src

# Dependencies
INCDIRS += $(SNDNN_DIR)/src
INCDIRS += $(SNDNN_DIR)/include

SRCS += $(SNDNN_DIR)/src/batchnorm.c
SRCS += $(SNDNN_DIR)/src/conv2d.c
SRCS += $(SNDNN_DIR)/src/gemm.c
SRCS += $(SNDNN_DIR)/src/maxpool.c

SRCS += $(CUR_DIR)/src/batchnorm_layer.c
SRCS += $(CUR_DIR)/src/conv2d_layer.c
SRCS += $(CUR_DIR)/src/gelu_layer.c
SRCS += $(CUR_DIR)/src/layernorm_layer.c
SRCS += $(CUR_DIR)/src/linear_layer.c
SRCS += $(CUR_DIR)/src/maxpool_layer.c
SRCS += $(CUR_DIR)/src/nnlinear_backend_baseline.c
SRCS += $(CUR_DIR)/src/softmax_layer.c

SRCS += $(SNDNN_DIR)/src/utils.c


###########
# Outputs #
###########

OBJS        = $(addprefix $(BUILDDIR)/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))
DEPS        = $(addprefix $(BUILDDIR)/,$(addsuffix .d,$(basename $(notdir $(SRCS)))))
LIB         = $(BUILDDIR)/libsnDNN.a
DUMP        = $(BUILDDIR)/libsnDNN.dump
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

###########
# Kernels #
###########

$(BUILDDIR)/%.o: $(SRC_DIR)/%.S | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: $(SRC_DIR)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -c $< -o $@

$(BUILDDIR)/%.d: $(SRC_DIR)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(@:.d=.o)' $< > $@

##########
# Layers #
##########

$(BUILDDIR)/%.o: $(SRC_DIR_LAYER)/%.S | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: $(SRC_DIR_LAYER)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -c $< -o $@

$(BUILDDIR)/%.d: $(SRC_DIR_LAYER)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(@:.d=.o)' $< > $@

###########
# Library #
###########
$(LIB): $(OBJS) | $(BUILDDIR)
	$(RISCV_AR) $(RISCV_ARFLAGS) $@ $^

$(DUMP): $(LIB) | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif
