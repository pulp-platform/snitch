# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

#######################
# Makefile invocation #
#######################

DEBUG        ?= OFF # ON to turn on debugging symbols
CFG_OVERRIDE ?=     # Override default config file

.DEFAULT_GOAL := help
.PHONY: all clean
all: update-rtl sw addrmap
clean: clean-bender clean-sw clean-addrmap clean-vlt clean-vsim clean-vcs clean-logs

############
# Makefrag #
############

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../..

include $(ROOT)/util/Makefrag

############
# Programs #
############

REGGEN     ?= $(shell $(BENDER) path register_interface)/vendor/lowrisc_opentitan/util/regtool.py
OCCAMYGEN  ?= $(ROOT)/util/occamygen.py
ADDRMAPGEN ?= $(ROOT)/util/addrmapgen.py

CLANG_FORMAT ?= $(shell which clang-format-12.0.1)

VSIM = vsim -64
VLOG = vlog -64

#########################
# Files and directories #
#########################

PLATFORM_HEADERS_DIR ?= sw/shared/platform/generated
CVA6_TRACE            = trace_hart_0.log

# If the configuration file is overriden on the command-line (through
# CFG_OVERRIDE) and this file differs from the least recently used
# (LRU) config, all targets depending on the configuration file have
# to be rebuilt. This file is used to express this condition as a
# prerequisite for other rules.
CFG = cfg/lru.hjson

#####################
# Simulator options #
#####################

VSIM_FLAGS += -t 1ps
VSIM_FLAGS += -voptargs=+acc
VSIM_FLAGS += -do "log -r /*; run -a"
# Downgraded from error as VSIM *wrongly* reports illegal enum assignments in riscv_dbg 4-phase CDCs
# TODO: Workaround; revise
VSIM_FLAGS += -warning 8386

VCS_FLAGS += +nospecify
VCS_FLAGS += -Mdir=work-vcs
VCS_FLAGS += -Mlib=work-vcs
VCS_FLAGS += -full64
# Multi-core
VCS_FLAGS += -fgp
# Debug Options
VCS_FLAGS += -assert disable_cover
VCS_FLAGS += -kdb
VCS_FLAGS += +vcs+fsdbon
VCS_FLAGS += +lint=TFIPC-L
VCS_FLAGS += -debug_access+all

VLOG_FLAGS += -svinputport=compat
VLOG_FLAGS += -override_timescale 1ns/1ps
VLOG_FLAGS += -suppress 2583
VLOG_FLAGS += -suppress 13314
VLOG_FLAGS += ${QUESTA_64BIT}
VLOG_FLAGS += -timescale 1ns/1ps
VLOG_FLAGS += +define+WT_DCACHE

# Verilated and compiled Occamy system
VLT_AR     = ${VLT_BUILDDIR}/Vtestharness__ALL.a
VLT_FLAGS += -Wno-SYMRSVDWORD -Wno-BLKLOOPINIT
VLT_FLAGS += --trace       # Enable VCD dumping
VLT_FLAGS += --prof-cfuncs # Enable code profiling

###############
# C testbench #
###############

TB_CC_SOURCES  = $(TB_DIR)/rtl_lib.cc
TB_CC_SOURCES += $(TB_DIR)/common_lib.cc
TB_CC_SOURCES += $(ROOT)/hw/system/occamy/test/bootdata.cc
TB_CC_SOURCES += $(ROOT)/hw/system/occamy/test/uartdpi/uartdpi.c

TB_CC_FLAGS  = -std=c++14
TB_CC_FLAGS +=-I$(MKFILE_DIR)
TB_CC_FLAGS +=-I$(MKFILE_DIR)/test
TB_CC_FLAGS +=-I$(FESVR)/include
TB_CC_FLAGS +=-I$(TB_DIR)
TB_CC_FLAGS +=-I$(ROOT)/hw/system/occamy/test/uartdpi

# Required C sources for the verilator TB that are linked against the verilated model
VLT_COBJ  = $(VLT_BUILDDIR)/tb/common_lib.o
VLT_COBJ += $(VLT_BUILDDIR)/tb/verilator_lib.o
VLT_COBJ += $(VLT_BUILDDIR)/tb/tb_bin.o
VLT_COBJ += $(VLT_BUILDDIR)/test/uartdpi/uartdpi.o
VLT_COBJ += $(VLT_BUILDDIR)/test/bootdata.o
# Sources from verilator root
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated.o
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated_dpi.o
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated_vcd_c.o

#################
# Prerequisites #
#################

$(CFG): FORCE
	@# If the LRU config file doesn't exist, we use the default config.
	@if [ ! -e $@ ] ; then \
		DEFAULT_CFG="cfg/full.hjson"; \
		echo "Using default config file: $$DEFAULT_CFG"; \
		cp $$DEFAULT_CFG $@; \
	fi
	@# If a config file is provided on the command-line and it differs
	@# from the LRU config file then we override the LRU file with it
	@if [ $(CFG_OVERRIDE) ] ; then \
		echo "Overriding config file with: $(CFG_OVERRIDE)"; \
		if cmp -s $(CFG_OVERRIDE) $@ ; then \
			echo "Override and LRU config files are equivalent. Nothing to be done."; \
		else \
			cp $(CFG_OVERRIDE) $@; \
		fi \
	fi
FORCE:

############
# Boot ROM #
############

BOOTROM_TARGETS = test/bootrom.elf test/bootrom.dump test/bootrom.bin

.PHONY: bootrom clean-bootrom

bootrom: $(BOOTROM_TARGETS)

clean-bootrom:
	rm -rf $(BOOTROM_TARGETS)

test/bootrom.elf: test/bootrom.S test/bootrom.ld
	riscv64-unknown-elf-gcc -mabi=lp64d -march=rv64imafd -static -nostartfiles -Ttest/bootrom.ld $< -o test/bootrom.elf
test/bootrom.dump: test/bootrom.elf
	riscv64-unknown-elf-objdump -D $< > $@
test/bootrom.bin: test/bootrom.elf
	riscv64-unknown-elf-objcopy -O binary $< $@

##########
# Source #
##########

.PHONY: update-rtl update-clint update-plic update-socreg update-quadreg update-source

update-rtl: update-clint update-plic update-socreg update-quadreg update-source

update-source: $(CFG)
	@echo "[SOLDER]  Generating sources"
	@echo "[SOLDER]  RTL"
	@$(OCCAMYGEN) --cfg $(CFG) --graph addrmap/addrmap.dot --outdir src --wrapper --memories \
		--top-sv src/occamy_top.sv.tpl \
		--soc-sv src/occamy_soc.sv.tpl \
		--pkg-sv src/occamy_pkg.sv.tpl \
		--quadrant-s1 src/occamy_quadrant_s1.sv.tpl \
		--quadrant-s1-ctrl src/occamy_quadrant_s1_ctrl.sv.tpl \
		--xilinx-sv src/occamy_xilinx.sv.tpl \
		--cva6-sv src/occamy_cva6.sv.tpl
	@$(OCCAMYGEN) --cfg $(CFG) --graph addrmap/addrmap.dot --am-csv addrmap/addrmap.csv \
		--outdir test \
		--testharness-sv test/testharness.sv.tpl \
		--bootdata ../../ip/snitch_cluster/test/bootdata.cc.tpl
	@echo "[SOLDER]  Device Tree"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir . --dts test/occamy.dts
	@echo "[VERIBLE] Formatting"
	@verible-verilog-format --inplace src/occamy_quadrant_s1.sv src/occamy_pkg.sv src/occamy_soc.sv src/occamy_top.sv src/occamy_xilinx.sv src/occamy_cva6.sv

CLINTROOT = $(shell $(BENDER) path clint)
update-clint: $(CFG)
	@mkdir -p src/clint
	@echo "[SOLDER]  Generate CLINT config"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir src/clint --chip $(CLINTROOT)/data/clint.hjson.tpl
	@$(OCCAMYGEN) --cfg $(CFG) --outdir src/clint --chip $(CLINTROOT)/data/clint.sv.tpl
	@echo "[REGGEN]  Generate CLINT regs"
	@$(REGGEN) -r -t src/clint src/clint/clint.hjson
	@verible-verilog-format --inplace src/clint/clint_reg_top.sv

PLICSRC = $(ROOT)/hw/vendor/pulp_platform_opentitan_peripherals/src/rv_plic
update-plic:
	@mkdir -p src/rv_plic
	@echo "[PLICGEN] Generate PLIC config"
	@$(PLICSRC)/util/reg_rv_plic.py -s 73 -t 2 -p 6 $(PLICSRC)/data/rv_plic.sv.tpl > src/rv_plic/rv_plic.sv
	@$(PLICSRC)/util/reg_rv_plic.py -s 73 -t 2 -p 6 $(PLICSRC)/data/rv_plic.hjson.tpl > src/rv_plic/rv_plic.hjson
	@echo "[REGGEN]  Generate PLIC regs"
	@$(REGGEN) -r -t src/rv_plic src/rv_plic/rv_plic.hjson
	@verible-verilog-format --inplace src/rv_plic/rv_plic_reg_top.sv

# Update generic control register.
# $1: config name, $2: output directory, $3: output filename stem
define update_ctrl_regs
	$(if $5, @echo "[REGGEN]  Generate $1 config" && \
		$(OCCAMYGEN) --cfg $(CFG) --outdir $2 --chip $2/$3.tpl)
	@echo "[REGGEN]  Generate $1"
	@$(REGGEN) -r $2/$3 --outdir $2
endef

update-socreg:
	$(call update_ctrl_regs,SOCREGS,src/occamy_soc_ctrl,occamy_soc_reg.hjson,occamy_soc_peripheral,1)
	@verible-verilog-format --inplace src/occamy_soc_ctrl/occamy_soc_reg_top.sv
	$(call update_ctrl_regs,HBMXBARREGS,src/occamy_hbm_xbar_ctrl,occamy_hbm_xbar_reg.hjson,occamy_hbm_xbar_peripheral,1)
	@verible-verilog-format --inplace src/occamy_hbm_xbar_ctrl/occamy_hbm_xbar_reg_top.sv

update-quadreg:
	$(call update_ctrl_regs,QUADREGS,src/occamy_quadrant_s1_ctrl,occamy_quadrant_s1_reg.hjson,occamy_quad_peripheral,1)
	@verible-verilog-format --inplace src/occamy_quadrant_s1_ctrl/occamy_quadrant_s1_reg_top.sv

###############
# Address Map #
###############

ADDRMAP_TARGETS = addrmap.tex addrmap.md addrmap.png addrmap.pdf

.PHONY: addrmap clean-addrmap

# Generate address map in all formats
addrmap: update-source $(ADDRMAP_TARGETS)

addrmap.png:
	dot -Tpng addrmap/addrmap.dot > addrmap/addrmap.png

addrmap.tex:
	@$(ADDRMAPGEN) --file addrmap/addrmap.csv --outdir addrmap --tex addrmap/addrmap.tex.tpl

addrmap.md:
	@$(ADDRMAPGEN) --file addrmap/addrmap.csv --outdir docs --md 2_addrmap.md

addrmap.pdf: addrmap.tex
	cd addrmap && latexmk -quiet -pdf addrmap.tex

clean-addrmap:
	rm -rf $(ADDRMAP_TARGETS)
	# Delete intermediate Latex outputs
	rm -rf addrmap/addrmap.aux
	rm -rf addrmap/addrmap.fdb*
	rm -rf addrmap/addrmap.fls
	rm -rf addrmap/addrmap.log

############
# Software #
############

PLATFORM_HEADERS  = $(PLATFORM_HEADERS_DIR)/occamy_cfg.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/occamy_base_addr.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/clint.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/occamy_soc_ctrl.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_cluster_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_quad_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_hbm_xbar_peripheral.h

.PHONY: sw clean-headers clean-sw

sw: $(PLATFORM_HEADERS)
	$(MAKE) -C sw/ all

clean-headers:
	rm -f $(PLATFORM_HEADERS)

clean-sw: clean-headers
	$(MAKE) -C sw/ clean

# REGGEN headers
$(PLATFORM_HEADERS_DIR)/clint.h: src/clint/clint.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/occamy_soc_ctrl.h: src/occamy_soc_ctrl/occamy_soc_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_cluster_peripheral.h: $(ROOT)/hw/ip/snitch_cluster/src/snitch_cluster_peripheral/snitch_cluster_peripheral_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_quad_peripheral.h: src/occamy_quadrant_s1_ctrl/occamy_quadrant_s1_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_hbm_xbar_peripheral.h: src/occamy_hbm_xbar_ctrl/occamy_hbm_xbar_reg.hjson
	$(call reggen_generate_header,$@,$<)

# OCCAMYGEN headers
$(PLATFORM_HEADERS_DIR)/occamy_cfg.h: $(PLATFORM_HEADERS_DIR)/occamy_cfg.h.tpl $(CFG)
	@echo "[OCCAMYGEN] Generating $@"
	@$(OCCAMYGEN) -c $(CFG) --outdir $(PLATFORM_HEADERS_DIR) --cheader $<
$(PLATFORM_HEADERS_DIR)/occamy_base_addr.h: $(CFG)
	@echo "[OCCAMYGEN] Generating $@"
	@$(OCCAMYGEN) -c $(CFG) --outdir $(PLATFORM_HEADERS_DIR) -D $@

##########
# Traces #
##########

# CVA6 trace should use binary written in logs/.rtlbinary
# which is retrieved by the Makefrag in the BINARY variable,
# but the Snitch traces use another binary which is expected to
# be passed on the command-line, overriding the BINARY variable.
# So we define a new variable to store the CVA6 binary
CVA6_BINARY ?= $(shell cat $(LOGS_DIR)/.rtlbinary)

$(LOGS_DIR)/hart_00000_perf.json: $(LOGS_DIR)/trace_hart_00000.txt $(ROOT)/util/trace/events.py
	$(PYTHON) $(ROOT)/util/trace/events.py -f cva6 $< -o $@

$(LOGS_DIR)/trace_hart_00000.s: $(LOGS_DIR)/trace_hart_00000.txt ${ANNOTATE}
	$(PYTHON) ${ANNOTATE} ${ANNOTATE_FLAGS} -o $@ $(CVA6_BINARY) $<

$(LOGS_DIR)/trace_hart_00000.diff: $(LOGS_DIR)/trace_hart_00000.txt ${ANNOTATE}
	$(PYTHON) ${ANNOTATE} ${ANNOTATE_FLAGS} -o $@ $(CVA6_BINARY) $< -d

traces: $(LOGS_DIR)/hart_00000_perf.json

annotate: $(shell (echo $(LOGS_DIR)/trace_hart_00000.txt | sed 's/\.txt/\.s/') || echo "") \
          $(shell (echo $(LOGS_DIR)/trace_hart_00000.txt | sed 's/\.txt/\.diff/') || echo "")

$(LOGS_DIR)/perf.csv: $(shell (ls $(LOGS_DIR)/trace_hart_*.dasm 2>/dev/null | sed 's/trace_hart/hart/' | sed 's/.dasm/_perf.json/')) \
		  $(LOGS_DIR)/hart_00000_perf.json $(ROOT)/util/trace/perf_csv.py
	$(PYTHON) $(ROOT)/util/trace/perf_csv.py -o $@ -i $(LOGS_DIR)/hart_*_perf.json

$(LOGS_DIR)/event.csv: $(shell (ls $(LOGS_DIR)/trace_hart_*.dasm 2>/dev/null | sed 's/trace_hart/hart/' | sed 's/.dasm/_perf.json/')) \
		  $(LOGS_DIR)/hart_00000_perf.json $(ROOT)/util/trace/perf_csv.py
	$(PYTHON) $(ROOT)/util/trace/perf_csv.py -o $@ -i $(LOGS_DIR)/hart_*_perf.json --filter tstart tend

#############
# Verilator #
#############

${VLT_AR}: ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,testharness)

# Quick sanity check, not really meant for simulation.
verilate: ${VLT_AR}

# Build targets for verilator TB
$(VLT_BUILDDIR)/tb/%.o: $(TB_DIR)/%.cc $(VLT_AR) ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@
$(VLT_BUILDDIR)/vlt/%.o: $(VLT_ROOT)/include/%.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@
$(VLT_BUILDDIR)/test/%.o: test/%.cc ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@

$(VLT_BUILDDIR)/test/uartdpi/uartdpi.o: test/uartdpi/uartdpi.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(VLT_CFLAGS) -c $< -o $@

# Link verilated archive wich $(VLT_COBJ)
bin/occamy_top.vlt: $(VLT_AR) $(VLT_COBJ) ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) -std=c++14 -L ${VLT_BUILDDIR}/lib -o $@ $(VLT_COBJ) $(VLT_AR) -lfesvr -lpthread -lutil

# Clean all build directories and temporary files for Verilator simulation
.PHONY: clean-vlt
clean-vlt: clean-work
	rm -rf work-vlt
	rm -f bin/occamy_top.vlt

############
# Modelsim #
############

${VSIM_BUILDDIR}/compile.vsim.tcl: $(VSIM_SOURCES) ${TB_SRCS} ${TB_CC_SOURCES} test/bootrom.bin
	vlib $(dir $@)
	${BENDER} script vsim ${VSIM_BENDER} --vlog-arg="${VLOG_FLAGS} -work $(dir $@) " > $@
	echo '${VLOG} -work $(dir $@) $(TB_CC_SOURCES) -ccflags "$(TB_CC_FLAGS)"' >> $@
	echo 'return 0' >> $@

# Build compilation script and compile all sources for Questasim simulation
# @IIS:
# CC=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/gcc
# CXX=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/g++
# LD=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/ld
bin/occamy_top.vsim: ${VSIM_BUILDDIR}/compile.vsim.tcl work/lib/libfesvr.a
	$(call QUESTASIM,tb_bin)
	@# Rename CVA6 trace to align with Snitch trace names
	@echo "mv ${CVA6_TRACE} $(LOGS_DIR)/trace_hart_00000.txt" >> $@
	@echo "mv ${CVA6_TRACE} $(LOGS_DIR)/trace_hart_00000.txt" >> $@.gui
	@# Move all other traces to logs folder as well
	@echo "mv *trace*.log $(LOGS_DIR)/" >> $@
	@echo "mv *trace*.log $(LOGS_DIR)/" >> $@.gui

# Clean all build directories and temporary files for Questasim simulation
clean-vsim: clean-work
	rm -rf bin/occamy_top.vsim bin/occamy_top.vsim.gui work-vsim vsim.wlf

#######
# VCS #
#######

# Build compilation script and compile all sources for VCS simulation
# @IIS: vcs-2020.12 make bin/occamy_top.vcs
# CC=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/gcc
# CXX=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/g++
# LD=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/ld
bin/occamy_top.vcs: work-vcs/compile.sh work/lib/libfesvr.a ${TB_CC_SOURCES} test/bootrom.bin
	mkdir -p bin
	vcs $(VCS_FLAGS) -o bin/occamy_top.vcs tb_bin -cc $(CC) -cpp $(CXX) \
		$(TB_CC_SOURCES) -CFLAGS "$(TB_CC_FLAGS)" -LDFLAGS "-L${FESVR}/lib" -lfesvr -lutil

# Clean all build directories and temporary files for VCS simulation
.PHONY: clean-vcs
clean-vcs: clean-work
	rm -rf AN.DB
	rm -rf work-vcs
	rm -f bin/occamy_top.vcs

########
# FPGA #
########

# Build a small Occamy version (CVA6 + 1 cluster) for the VCU128 FPGA board
.PHONY: fpga
fpga:
	${MAKE} -C fpga occamy_vcu128

########
# Util #
########

.PHONY: clean-work clean-bender clean-logs help

clean-work:
	rm -rf work

clean-bender:
	rm -rf Bender.lock .bender/ work/

clean-logs:
	rm -rf $(LOGS_DIR)/

# Help command
Blue=\033[1;34m
Black=\033[0m
help:
	@echo -e "${Blue}Makefile Targets${Black} for the ${Blue}Snitch Cluster${Black}"
	@echo -e "Use 'make <target>' where <target> is one of:"
	@echo -e ""
	@echo -e "${Blue}help           ${Black}Show an overview of all Makefile targets."
	@echo -e ""
	@echo -e "${Blue}bin/occamy_top.vcs  ${Black}Build compilation script and compile all sources for VCS simulation. @IIS: vcs-2020.12 make bin/occamy_top.vcs"
	@echo -e "${Blue}bin/occamy_top.vlt  ${Black}Build compilation script and compile all sources for Verilator simulation."
	@echo -e "${Blue}bin/occamy_top.vsim ${Black}Build compilation script and compile all sources for Questasim simulation. @IIS: QUESTA_HOME=/usr/pack/modelsim-10.7b-kgf/questasim/ CC=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/gcc CXX=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/g++ LD=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/ld make bin/occamy_top.vsim"
	@echo -e ""
	@echo -e "${Blue}all            ${Black}Update all SW and HW related sources (by, e.g., re-generating the RegGen registers and their c-header files)."
	@echo -e "${Blue}fpga           ${Black}Build a small Occamy version (CVA6 + 1xcluster) for the VCU128 FPGA board."
	@echo -e ""
	@echo -e "${Blue}addrmap        ${Black}Generate the addressmap in the following formats: MD, PNG, TEX, PDF."
	@echo -e "${Blue}addrmap.tex    ${Black}Generate the TEX addrmap source."
	@echo -e "${Blue}addrmap.md     ${Black}Generate the MD addrmap graphic."
	@echo -e "${Blue}addrmap.png    ${Black}Generate the PNG addrmap graphic."
	@echo -e "${Blue}addrmap.pdf    ${Black}Generate the PDF addrmap graphic."
	@echo -e ""
	@echo -e "${Blue}clean          ${Black}Clean everything except traces in logs directory."
	@echo -e "${Blue}clean-bender   ${Black}Clean all Bender generated files."
	@echo -e "${Blue}clean-sw       ${Black}Clean all software."
	@echo -e "${Blue}clean-addrmap  ${Black}Delete all addrmap outputs."
	@echo -e "${Blue}clean-logs     ${Black}Delete all traces in logs directory."
	@echo -e "${Blue}clean-vcs      ${Black}Clean all build directories and temporary files for VCS simulation."
	@echo -e "${Blue}clean-vlt      ${Black}Clean all build directories and temporary files for Verilator simulation."
	@echo -e "${Blue}clean-vsim     ${Black}Clean all build directories and temporary files for Questasim simulation."
	@echo -e ""
	@echo -e "${Blue}sw             ${Black}Build all software."
	@echo -e ""
	@echo -e "Additional useful targets from the included Makefrag:"
	@echo -e "${Blue}traces         ${Black}Generate the better readable traces in .logs/trace_hart_<hart_id>.txt with spike-dasm."
	@echo -e "${Blue}annotate       ${Black}Annotate the better readable traces in .logs/trace_hart_<hart_id>.s with the source code related with the retired instructions."
