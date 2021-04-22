# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

include runtime/runtime.mk

all: bin/large_lfsr
all: bin/dummy
all: bin/frep_single
all: bin/frep_multiple
all: bin/sdma_single_tcdm
all: bin/matmul_baseline
all: bin/matmul_ssr
all: bin/matmul_ssr_frep
all: bin/multi_core
all: bin/multi_cluster
all: bin/barrier
all: bin/loads
all: bin/stores
all: bin/unpred_jr_1
all: bin/unpred_jr_2
all: bin/far_jump
all: bin/atomics
all: bin/wfi

bin/%: %.c
	mkdir -p $(shell dirname $@) dump
	$(RISCV_CC) -Iinclude $(RISCV_LDFLAGS) -o $@ $^ -Truntime/link.ld runtime/billywig_crt0.S
	$(RISCV_STRIP) $@ -g -S -d --strip-debug
	$(RISCV_OBJDUMP) -D $@ > dump/$*.dump

bin/%: %.s
	mkdir -p $(shell dirname $@) dump
	$(RISCV_CC) -Iinclude $(RISCV_LDFLAGS) -o $@ $^ -Truntime/link.ld
	$(RISCV_STRIP) $@ -g -S -d --strip-debug
	$(RISCV_OBJDUMP) -D $@ > dump/$*.dump

matmul/data.S: matmul/gen_data.py
	$(PYTHON) $< > $@

bin/matmul_baseline: matmul/data.S
bin/matmul_ssr: matmul/data.S
bin/matmul_ssr_frep: matmul/data.S

# LLVM Tests: require snitch-llvm extensions
# TODO: Some binaries are not reproducible, with optimizations removing instructions
include runtime/runtime.llvm.mk

LLVM_TESTS = \
bin/fmv \
bin/fcvt \
bin/ssr_inst_check \
bin/ssr_multi_use \
bin/sdma_simple \
bin/dotp_ssr_frep \
bin/spvv_issr_frep \
bin/spmv_issr_frep \
bin/spmm_issr_frep \

all: $(LLVM_TESTS)

$(LLVM_TESTS): bin/%: %.c
	mkdir -p $(shell dirname $@) dump
	$(RISCV_LLVM_CC) $(RISCV_LLVM_CCFLAGS) -Iinclude $(RISCV_LLVM_LDFLAGS) -o $@ $^ -Truntime/link.ld runtime/billywig_crt0.S
	$(RISCV_LLVM_STRIP) $@ $(RISCV_LLVM_STRIP_FLAGS)
	$(RISCV_LLVM_OBJDUMP) $(RISCV_LLVM_OBJDUMP_FLAGS) -D $@ > dump/$*.dump
