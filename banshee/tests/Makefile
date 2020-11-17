DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/../../sw
VPATH += $(DIR)
include $(DIR)/runtime/runtime.mk

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

bin/%: %.c
	mkdir -p $(shell dirname $@) dump
	$(RISCV_CC) -Iinclude $(RISCV_LDFLAGS) -o $@ $^ -T$(DIR)/runtime/link.ld $(DIR)/runtime/billywig_crt0.S
	$(RISCV_STRIP) $@ -g -S -d --strip-debug
	$(RISCV_OBJDUMP) -D $@ > dump/$*.dump

bin/%: %.s
	mkdir -p $(shell dirname $@) dump
	$(RISCV_CC) -Iinclude $(RISCV_LDFLAGS) -o $@ $^ -T$(DIR)/runtime/link.ld
	$(RISCV_STRIP) $@ -g -S -d --strip-debug
	$(RISCV_OBJDUMP) -D $@ > dump/$*.dump

bin/matmul_baseline: matmul/data.S
bin/matmul_ssr: matmul/data.S
bin/matmul_ssr_frep: matmul/data.S
