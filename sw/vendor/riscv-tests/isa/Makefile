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
include $(src_dir)/rv64uzfh/Makefrag
include $(src_dir)/rv64si/Makefrag
include $(src_dir)/rv64ssvnapot/Makefrag
include $(src_dir)/rv64mi/Makefrag
endif
include $(src_dir)/rv32ui/Makefrag
include $(src_dir)/rv32uc/Makefrag
include $(src_dir)/rv32um/Makefrag
include $(src_dir)/rv32ua/Makefrag
include $(src_dir)/rv32uf/Makefrag
include $(src_dir)/rv32ud/Makefrag
include $(src_dir)/rv32uzfh/Makefrag
include $(src_dir)/rv32si/Makefrag
include $(src_dir)/rv32mi/Makefrag
include $(src_dir)/rv32uxpulpabs/Makefrag
include $(src_dir)/rv32uxpulpbitop/Makefrag
include $(src_dir)/rv32uxpulpbr/Makefrag
include $(src_dir)/rv32uxpulpclip/Makefrag
include $(src_dir)/rv32uxpulpmacsi/Makefrag
include $(src_dir)/rv32uxpulpminmax/Makefrag
include $(src_dir)/rv32uxpulppostmod/Makefrag
include $(src_dir)/rv32uxpulpslet/Makefrag
include $(src_dir)/rv32uxpulpvect/Makefrag
include $(src_dir)/rv32uxpulpvectshufflepack/Makefrag

default: all

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

# TODO: if integrating in Mempool move all Mempool related things in this Makefile
# outside of riscv-tests
MEMPOOL_DIR       := $(shell git rev-parse --show-toplevel 2>/dev/null || echo $$MEMPOOL_DIR)
INSTALL_DIR       ?= $(MEMPOOL_DIR)/install
GCC_INSTALL_DIR   ?= $(INSTALL_DIR)/riscv-gcc
SPIKE_INSTALL_DIR ?= $(INSTALL_DIR)/riscv-isa-sim

RISCV_PREFIX ?= riscv$(XLEN)-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
# TODO: update with new compiler which separates Xpulp partitions
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassembler-option="march=rv32gXpulpimg" --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
RISCV_SIM ?= spike

vpath %.S $(src_dir)

#------------------------------------------------------------
# Build assembly tests

%.dump: %
	$(RISCV_OBJDUMP) $< > $@

%.out: %
	PATH="$(MEMPOOL_DIR)/install/riscv-isa-sim/bin:$$PATH"; \
	$(RISCV_SIM) --isa=rv64gc $< 2> $@

%.out32: %
	PATH="$(MEMPOOL_DIR)/install/riscv-isa-sim/bin:$$PATH"; \
	$(RISCV_SIM) --isa=rv32gc $< 2> $@

define compile_template

$$($(1)_p_tests): $(1)-p-%: $(1)/%.S
	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -I$(src_dir)/../env/p -I$(src_dir)/macros/scalar -T$(src_dir)/../env/p/link.ld $$< -o $$@
$(1)_tests += $$($(1)_p_tests)

$$($(1)_v_tests): $(1)-v-%: $(1)/%.S
	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -DENTROPY=0x$$(shell echo \$$@ | md5sum | cut -c 1-7) -std=gnu99 -O2 -I$(src_dir)/../env/v -I$(src_dir)/macros/scalar -T$(src_dir)/../env/v/link.ld $(src_dir)/../env/v/entry.S $(src_dir)/../env/v/*.c $$< -o $$@
$(1)_tests += $$($(1)_v_tests)

$(1)_tests_dump = $$(addsuffix .dump, $$($(1)_tests))

$(1): $$($(1)_tests_dump)

.PHONY: $(1)

COMPILER_SUPPORTS_$(1) := $$(shell $$(RISCV_GCC) $(2) -c -x c /dev/null -o /dev/null 2> /dev/null; echo $$$$?)

ifeq ($$(COMPILER_SUPPORTS_$(1)),0)
tests += $$($(1)_tests)
endif

endef

$(eval $(call compile_template,rv32ui,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uc,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32um,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32ua,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uf,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32ud,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uzfh,-march=rv32g_zfh -mabi=ilp32))
$(eval $(call compile_template,rv32si,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32mi,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpabs,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpbitop,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpbr,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpclip,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpmacsi,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpminmax,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulppostmod,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpslet,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpvect,-march=rv32gXpulpimg -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpvectshufflepack,-march=rv32gXpulpimg -mabi=ilp32))

ifeq ($(XLEN),64)
$(eval $(call compile_template,rv64ui,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uc,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64um,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ua,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uf,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ud,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uzfh,-march=rv64g_zfh -mabi=lp64))
$(eval $(call compile_template,rv64si,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ssvnapot,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64mi,-march=rv64g -mabi=lp64))
endif

tests_dump = $(addsuffix .dump, $(tests))
tests_hex = $(addsuffix .hex, $(tests))
tests_out = $(addsuffix .out, $(filter rv64%,$(tests)))
tests32_out = $(addsuffix .out32, $(filter rv32%,$(tests)))

run: $(tests_out) $(tests32_out)

junk += $(tests) $(tests_dump) $(tests_hex) $(tests_out) $(tests32_out)

#------------------------------------------------------------
# Default

all: $(tests_dump)

#------------------------------------------------------------
# Clean up

clean:
	rm -rf $(junk)
