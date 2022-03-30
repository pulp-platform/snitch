#=======================================================================
# Makefile for riscv-tests/isa
#-----------------------------------------------------------------------

XLEN ?= 32

src_dir := .

ifeq ($(XLEN),64)
include $(src_dir)/rv64ui/Makefrag
include $(src_dir)/rv64uc/Makefrag
include $(src_dir)/rv64um/Makefrag
include $(src_dir)/rv64ua/Makefrag
include $(src_dir)/rv64uf/Makefrag
include $(src_dir)/rv64ud/Makefrag
include $(src_dir)/rv64si/Makefrag
include $(src_dir)/rv64mi/Makefrag
endif
include $(src_dir)/rv32ui/Makefrag
include $(src_dir)/rv32uc/Makefrag
include $(src_dir)/rv32um/Makefrag
include $(src_dir)/rv32ua/Makefrag
include $(src_dir)/rv32uf/Makefrag
include $(src_dir)/rv32ud/Makefrag
include $(src_dir)/rv32si/Makefrag
include $(src_dir)/rv32mi/Makefrag
include $(src_dir)/rv32uxpulpimg/Makefrag

default: all

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

SNITCH_DIR       := $(shell git rev-parse --show-toplevel 2>/dev/null || echo $$SNITCH_DIR)
VENDOR_DIR       ?= $(SNITCH_DIR)/sw/vendor
LLVM_INSTALL_DIR ?= $(VENDOR_DIR)/riscv32-pulp-llvm-centos7-0.12.0
SPIKE_INSTALL_DIR ?= $(VENDOR_DIR)/riscv-isa-sim

RISCV_PREFIX ?= $(LLVM_INSTALL_DIR)/bin/riscv$(XLEN)-unknown-elf-
RISCV_LLVM ?= $(RISCV_PREFIX)clang
RISCV_LLVM_OPTS ?= -mcmodel=medany -ffast-math -fno-builtin-printf -fno-common -ffunction-sections -Wextra -static
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassembler-option="march=rv32gxpulpv2" --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
RISCV_SIM ?= $(SPIKE_INSTALL_DIR)/bin/spike

vpath %.S $(src_dir)

#------------------------------------------------------------
# Build assembly tests

%.dump: %
	$(RISCV_OBJDUMP) $< > $@

%.out: %
	PATH="$(VENDOR_DIR)/riscv-isa-sim/bin:$$PATH"; \
	$(RISCV_SIM) --isa=rv64gc $< 2> $@

%.out32: %
	PATH="$(VENDOR_DIR)/riscv-isa-sim/bin:$$PATH"; \
	$(RISCV_SIM) --isa=rv32gc $< 2> $@

define compile_template

$$($(1)_p_tests): $(1)-p-%: $(1)/%.S
	$$(RISCV_LLVM) $(2) $$(RISCV_LLVM_OPTS) -I$(src_dir)/../env/p -I$(src_dir)/macros/scalar -T$(src_dir)/../env/p/link.ld $$< -o $$@
$(1)_tests += $$($(1)_p_tests)

$$($(1)_v_tests): $(1)-v-%: $(1)/%.S
	$$(RISCV_LLVM) $(2) $$(RISCV_LLVM_OPTS) -DENTROPY=0x$$(shell echo \$$@ | md5sum | cut -c 1-7) -std=gnu99 -O2 -I$(src_dir)/../env/v -I$(src_dir)/macros/scalar -T$(src_dir)/../env/v/link.ld $(src_dir)/../env/v/entry.S $(src_dir)/../env/v/*.c $$< -o $$@
$(1)_tests += $$($(1)_v_tests)

$(1)_tests_dump = $$(addsuffix .dump, $$($(1)_tests))

$(1): $$($(1)_tests_dump)

.PHONY: $(1)

tests += $$($(1)_tests)

endef

$(eval $(call compile_template,rv32uxpulpimg,-march=rv32gxpulpv2 -mabi=ilp32d))


tests_dump = $(addsuffix .dump, $(tests))
tests_hex = $(addsuffix .hex, $(tests))
tests_out = $(addsuffix .out, $(spike_tests))
tests32_out = $(addsuffix .out32, $(spike32_tests))

run: $(tests_out) $(tests32_out)

junk += $(tests) $(tests_dump) $(tests_hex) $(tests_out) $(tests32_out)

#------------------------------------------------------------
# Default

all: $(tests_dump)

#------------------------------------------------------------
# Clean up

clean:
	rm -rf $(junk)
