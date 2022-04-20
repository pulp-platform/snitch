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
MEMPOOL_DIR      := /scratch/msc22f9/mempool
INSTALL_DIR       ?= $(MEMPOOL_DIR)/install
GCC_INSTALL_DIR   ?= /scratch/msc22f9/mempool/install/riscv-gcc
SPIKE_INSTALL_DIR ?= /scratch/msc22f9/mempool/install/riscv-isa-sim
HW_DIR					 := /hw/system/snitch_cluster

RISCV_PREFIX ?= $(GCC_INSTALL_DIR)/bin/riscv$(XLEN)-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassembler-option="march=rv32gXpulpimg" --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
RISCV_SIM ?= $(SPIKE_INSTALL_DIR)/bin/spike

vpath %.S $(src_dir)

#------------------------------------------------------------
# Build assembly tests

%.dump: %
	$(RISCV_OBJDUMP) $< > $@

%.out: %
	PATH="$(INSTALL_DIR)/riscv-isa-sim/bin:$$PATH"; \
	$(RISCV_SIM) --isa=rv64gc $< 2> $@

%.out32: %
	PATH="$(INSTALL_DIR)/riscv-isa-sim/bin:$$PATH"; \
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

tests += $$($(1)_tests)

endef

$(eval $(call compile_template,rv32ui,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uc,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32um,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32ua,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uf,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32ud,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32si,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32mi,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uxpulpimg,-march=rv32gXpulpimg -mabi=ilp32))
ifeq ($(XLEN),64)
$(eval $(call compile_template,rv64ui,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uc,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64um,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ua,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uf,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ud,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64si,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64mi,-march=rv64g -mabi=lp64))
endif

tests_dump = $(addsuffix .dump, $(tests))
tests_hex = $(addsuffix .hex, $(tests))
tests_out = $(addsuffix .out, $(spike_tests))
tests32_out = $(addsuffix .out32, $(spike32_tests))

run: $(tests_out) $(tests32_out)

junk += $(tests) $(tests_dump) $(tests_hex) $(tests_out) $(tests32_out)

include scratch/msc22f9/snitch/util/Makefrag
simc:
	${QUESTASIM} vsim -64 +permissive -work /scratch/msc22f9/snitch/hw/system/snitch_cluster//work-vsim -c -ldflags "-Wl,-rpath,/scratch/msc22f9/snitch/hw/system/snitch_cluster/work/lib -L/scratch/msc22f9/snitch/hw/system/snitch_cluster/work/lib -lfesvr -lutil" -t 1ps -voptargs=+acc tb_bin +permissive-off ++$1 -do "log -r /*; run -a"
sim:
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_abs
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_beqimm
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_bneimm
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_clip
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_clipr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_clipu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_clipur
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_extbs
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_extbz
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_exths
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_exthz
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lb_irpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lb_rr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lb_rrpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lbu_irpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lbu_rr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lbu_rrpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lh_irpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lh_rr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lh_rrpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lhu_irpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lhu_rr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lhu_rrpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lw_irpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lw_rr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_lw_rrpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_mac
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_max
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_maxu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_min
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_minu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_msu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sb_irpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sb_rr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sb_rrpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sh_irpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sh_rr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sh_rrpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_slet
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sletu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sw_rr
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-p_sw_rrpost
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_abs
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_add
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_and
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_avg
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_avgu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_dotsp
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_dotusp
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_extract
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_extractu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_insert
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_max
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_maxu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_min
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_minu
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_or
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_sdotup
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_sdotusp
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_shuffle2
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_sll
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_sra
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_srl
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_sub
	../../..$(HW_DIR)/bin/snitch_cluster.vsim rv32uxpulpimg-p-pv_xor
	cd ../



#------------------------------------------------------------
# Default

all: $(tests_dump)

#------------------------------------------------------------
# Clean up

clean:
	rm -rf $(junk)
