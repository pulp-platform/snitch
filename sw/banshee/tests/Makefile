# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

include runtime/runtime.mk

all: bin/large_lfsr
all: bin/dummy
all: bin/frep_single
all: bin/frep_multiple
all: bin/dma_simple
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
all: bin/fmv
all: bin/ssr_inst_check
all: bin/fcvt
all: bin/ssr_multi_use
all: bin/sdma_simple

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
