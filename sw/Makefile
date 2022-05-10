SHELL = /usr/bin/env bash
ROOT_DIR := /scratch/msc22f9/mempool/software
SNITCH_DIR := /scratch/msc22f9/snitch
RUNTIME_DIR := $(ROOT_DIR)/runtime
TESTS_DIR := $(SNITCH_DIR)/sw/riscv-tests/isa
TOOLCHAIN_DIR := $(abspath $(ROOT_DIR)/../toolchain)

MEMPOOL_DIR       := $(shell git rev-parse --show-toplevel 2>/dev/null || echo $$MEMPOOL_DIR)
MEMPOOL_NEW_DIR	  ?= /scratch/msc22f9/mempool-archived
INSTALL_DIR       ?= /scratch/msc22f9/mempool/install
GCC_INSTALL_DIR   ?= $(INSTALL_DIR)/riscv-gcc
SPIKE_INSTALL_DIR ?= $(INSTALL_DIR)/riscv-isa-sim
GCC_NEW_DIR				?= /usr/scratch2/toscana/sriedel/tc-riscv-gcc-xpulpnn/install/riscv-gcc

RISCV_PREFIX ?= $(GCC_NEW_DIR)/bin/riscv32-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -static -march=rv32imaXpulpimg -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles

# This will overwrite the ROOT_DIR variable from the included makefile
#include $(RUNTIME_DIR)/runtime.mk
include $(TESTS_DIR)/snitch_isa.mk

# Unit tests
TESTS := $(addprefix bin/,$(rtl_mempool_tests))

src_dir := $(abspath /scratch/msc22f9/snitch/sw/riscv-tests/isa)

define rtl_mempool_tests_template

TESTS_$(1) := $(addprefix bin/,$($(1)_mempool_tests))

$$(TESTS_$(1)): bin/$(1)-%: $(TESTS_DIR)/$(1)/%.S
	mkdir -p $$(shell dirname $$@)
	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -I$(src_dir)/../env/p -I$(src_dir)/macros/scalar -T$(src_dir)/../env/p/link.ld $$< -o $$@
#	$$(RISCV_CC) $$(RISCV_CCFLAGS_TESTS) -T$$(RUNTIME_DIR)/link.ld $$< -o $$@
#	$$(RISCV_STRIP) $$@ -g -S -d --strip-debug
#	$$(RISCV_OBJDUMP) $(RISCV_OBJDUMP_FLAGS) -D $$@ > $$@.dump

endef

$(eval $(call rtl_mempool_tests_template,rv32uxpulpimg))

test:  update_opcodes $(TESTS)

clean-test:
	rm -vf $(RUNTIME)
	rm -vf $(LINKER_SCRIPT)
	rm -vf $(TESTS)
	rm -vf $(addsuffix .dump,$(TESTS))

# Helper targets
.PHONY: update_opcodes
update_opcodes:
	make -C $(MEMPOOL_NEW_DIR)/toolchain/riscv-opcodes all

.PHONY: clean
clean: clean-test
