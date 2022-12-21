# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

DEBUG ?= OFF # ON to turn on debugging symbols

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../..

include $(ROOT)/util/Makefrag

REGGEN        ?= ${ROOT}/util/regtool.py
OCCAMYGEN     ?= ${ROOT}/util/occamygen.py

CLANG_FORMAT  ?= $(shell which clang-format-10.0.1)

VSIM      		= vsim -64
VLOG      		= vlog -64

CVA6_TRACE = trace_hart_0.log

TB_CC_SOURCES += \
	$(TB_DIR)/rtl_lib.cc \
	$(TB_DIR)/common_lib.cc \
	$(ROOT)/hw/system/occamy/test/bootdata.cc \
	$(ROOT)/hw/system/occamy/test/uartdpi/uartdpi.c

TB_CC_FLAGS += \
	-std=c++14 \
	-I$(MKFILE_DIR) \
	-I$(MKFILE_DIR)/test \
	-I$(FESVR)/include \
	-I$(TB_DIR) \
	-I$(ROOT)/hw/system/occamy/test/uartdpi

# Required C sources for the verilator TB that are linked against the verilated model
VLT_COBJ += \
    $(VLT_BUILDDIR)/tb/common_lib.o \
	$(VLT_BUILDDIR)/tb/verilator_lib.o \
	$(VLT_BUILDDIR)/tb/tb_bin.o \
	$(VLT_BUILDDIR)/test/uartdpi/uartdpi.o \
	$(VLT_BUILDDIR)/test/bootdata.o
# Sources from verilator root
VLT_COBJ += \
	$(VLT_BUILDDIR)/vlt/verilated.o \
	$(VLT_BUILDDIR)/vlt/verilated_dpi.o \
	$(VLT_BUILDDIR)/vlt/verilated_vcd_c.o

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

# Verilated and compiled Occamy system
VLT_AR     = ${VLT_BUILDDIR}/Vtestharness__ALL.a
VLT_FLAGS += -Wno-SYMRSVDWORD -Wno-BLKLOOPINIT
VLT_FLAGS += --trace       # Enable VCD dumping
VLT_FLAGS += --prof-cfuncs # Enable code profiling


CFG ?= src/occamy_cfg.hjson
REG_INCDIR ?= ${ROOT}/sw/snRuntime/include/

all: update-rtl update-sw addrmap

#################
# Prerequisites #
#################

test/bootrom.elf test/bootrom.dump test/bootrom.bin: test/bootrom.S test/bootrom.ld
	riscv64-unknown-elf-gcc -mabi=lp64d -march=rv64imafd -static -nostartfiles -Ttest/bootrom.ld $< -o test/bootrom.elf
	riscv64-unknown-elf-objdump -D test/bootrom.elf > test/bootrom.dump
	riscv64-unknown-elf-objcopy -O binary test/bootrom.elf test/bootrom.bin

##########
# Source #
##########

.PHONY: update-rtl update-clint update-plic update-socreg update-quadreg update-source

update-rtl: update-clint update-plic update-socreg update-quadreg update-source

update-source:
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
	@$(OCCAMYGEN) --cfg $(CFG) --graph addrmap/addrmap.dot --am-csv addrmap/addrmap.csv --am-cheader $(REG_INCDIR)/occamy_base_addr.h \
		--outdir test \
		--testharness-sv test/testharness.sv.tpl \
		--bootdata ../../ip/snitch_cluster/test/bootdata.cc.tpl
	@echo "[SOLDER]  CLINT"
	@echo "[SOLDER]  Device Tree"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir . --dts test/occamy.dts
	@echo "[VERIBLE] Formatting"
	@verible-verilog-format --inplace src/occamy_quadrant_s1.sv src/occamy_pkg.sv src/occamy_soc.sv src/occamy_top.sv src/occamy_xilinx.sv src/occamy_cva6.sv

update-clint:
	@mkdir -p src/clint
	@echo "[SOLDER]  Generate CLINT config"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir src/clint \
		--chip ../../ip/clint/data/clint.hjson.tpl
	@$(OCCAMYGEN) --cfg $(CFG) --outdir src/clint \
		--chip ../../ip/clint/data/clint.sv.tpl
	@echo "[REGGEN]  Re-generate CLINT regs"
	@$(REGGEN) -r -t src/clint src/clint/clint.hjson

update-plic:
	@mkdir -p src/rv_plic
	@echo "[REGGEN]  Generate PLIC"
	@$(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/util/reg_rv_plic.py -s 73 -t 2 -p 6 $(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/data/rv_plic.sv.tpl > src/rv_plic/rv_plic.sv
	@$(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/util/reg_rv_plic.py -s 73 -t 2 -p 6 $(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/data/rv_plic.hjson.tpl > src/rv_plic/rv_plic.hjson
	@$(REGGEN) -r -t src/rv_plic src/rv_plic/rv_plic.hjson

# Update generic control register.
# $1: config name, $2: output directory, $3: output filename stem, $4: header filename stem
define update_ctrl_regs
	$(if $5, @echo "[REGGEN]  Generate $1 config" && \
		$(OCCAMYGEN) --cfg $(CFG) --outdir $2 --chip $2/$3.tpl)
	@echo "[REGGEN]  Generate $1"
	@$(REGGEN) -r $2/$3 --outdir $2
	@echo "[REGGEN]  Generate $1 CDEFS"
	@$(REGGEN) --cdefines --outfile $(REG_INCDIR)/${4}.h $2/$3
	@$(CLANG_FORMAT) -i $(REG_INCDIR)/${4}.h
endef

update-socreg:
	$(call update_ctrl_regs,SOCREGS,src/occamy_soc_ctrl,occamy_soc_reg.hjson,occamy_soc_peripheral,1)
	$(call update_ctrl_regs,HBMXBARREGS,src/occamy_hbm_xbar_ctrl,occamy_hbm_xbar_reg.hjson,occamy_hbm_xbar_peripheral,1)

update-quadreg:
	$(call update_ctrl_regs,QUADREGS,src/occamy_quadrant_s1_ctrl,occamy_quadrant_s1_reg.hjson,occamy_quad_peripheral,1)

###############
# Address Map #
###############

# Generate all addressmaps
update-addrmap: addrmap.tex addrmap.md

addrmap: update-source update-addrmap addrmap.png addrmap.pdf

addrmap.png: update-source
	dot -Tpng addrmap/addrmap.dot > addrmap/addrmap.png

addrmap.tex: update-source
	@$(ROOT)/util/addrmapgen.py --file addrmap/addrmap.csv --outdir addrmap --tex addrmap/addrmap.tex.tpl

addrmap.md: update-source
	@$(ROOT)/util/addrmapgen.py --file addrmap/addrmap.csv --outdir $(ROOT)/docs/ug/ --md occamy_addrmap.md

addrmap.pdf: addrmap.tex
	cd addrmap && latexmk -quiet -pdf addrmap.tex

clean-addrmap.pdf:
	rm -rf addrmap/addrmap.aux
	rm -rf addrmap/addrmap.fdb*
	rm -rf addrmap/addrmap.fls
	rm -rf addrmap/addrmap.log
	rm -rf addrmap/addrmap.pdf

clean-addrmap: clean-addrmap.pdf
	rm -rf addrmap.png

############
# Software #
############

.PHONY: update-headers update-binaries update-sw

update-sw: update-headers update-binaries

update-binaries:
	make -C sw DEBUG=$(DEBUG) clean all

update-headers:
	@echo "[SOLDER] Generating headers"
	@$(OCCAMYGEN) -c $(CFG) --outdir sw/include/ --cheader sw/include/occamy_cfg.h.tpl
	@$(OCCAMYGEN) -c $(CFG) --outdir sw/include/ -D sw/include/occamy_addrmap.h
	@echo "[REGTOOL] Generating headers"
	@$(REGGEN) -D -o sw/include/clint.h src/clint/clint.hjson
	@$(REGGEN) -D -o sw/include/occamy_soc_ctrl.h src/occamy_soc_ctrl/occamy_soc_reg.hjson
	@$(REGGEN) -D -o sw/include/snitch_cluster_peripheral.h $(ROOT)/hw/ip/snitch_cluster/src/snitch_cluster_peripheral/snitch_cluster_peripheral_reg.hjson
	@$(REGGEN) -D -o sw/include/snitch_quad_peripheral.h src/occamy_quadrant_s1_ctrl/occamy_quadrant_s1_reg.hjson
	@$(REGGEN) -D -o sw/include/snitch_hbm_xbar_peripheral.h src/occamy_hbm_xbar_ctrl/occamy_hbm_xbar_reg.hjson

##########
# Traces #
##########

# CVA6 trace should use binary written in logs/.rtlbinary
# which is retrieved by the Makefrag in the BINARY variable,
# but the Snitch traces use another binary which is expected to
# be passed on the command-line, overriding the BINARY variable.
# So we define a new variable to store the CVA6 binary
CVA6_BINARY ?= $(shell cat logs/.rtlbinary)

logs/hart_00000_perf.json: logs/trace_hart_00000.txt $(ROOT)/util/trace/events.py
	$(PYTHON) $(ROOT)/util/trace/events.py -f cva6 $< -o $@

logs/trace_hart_00000.s logs/trace_hart_00000.diff: logs/trace_hart_00000.txt ${ANNOTATE}
	$(PYTHON) ${ANNOTATE} -q -o $@ $(CVA6_BINARY) $< -d

traces: logs/hart_00000_perf.json

annotate: $(shell (echo logs/trace_hart_00000.txt | sed 's/\.txt/\.s/') || echo "") \
          $(shell (echo logs/trace_hart_00000.txt | sed 's/\.txt/\.diff/') || echo "")

perf-csv: $(shell (ls logs/trace_hart_*.dasm 2>/dev/null | sed 's/trace_hart/hart/' | sed 's/.dasm/_perf.json/')) \
		  logs/hart_00000_perf.json $(ROOT)/util/trace/perf_csv.py
	$(PYTHON) $(ROOT)/util/trace/perf_csv.py logs logs/perf_metrics.csv

clean-annotate:
	rm -f logs/*.s logs/*.diff

#############
# Verilator #
#############

${VLT_AR}: ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,testharness)

# Quick sanity check, not really meant for simulation.
verilate: ${VLT_AR}

clean-vlt-obj:
	rm $(VLT_COBJ)

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

.PHONY: clean-vlt
clean-vlt:
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

bin/occamy_top.vsim: ${VSIM_BUILDDIR}/compile.vsim.tcl work/lib/libfesvr.a
	$(call QUESTASIM,tb_bin)
	@# Rename CVA6 trace to align with Snitch trace names
	@echo "mv ${CVA6_TRACE} logs/trace_hart_00000.txt" >> $@
	@echo "mv ${CVA6_TRACE} logs/trace_hart_00000.txt" >> $@.gui
	@# Move all other traces to logs folder as well
	@echo "mv *trace*.log logs/" >> $@
	@echo "mv *trace*.log logs/" >> $@.gui

#######
# VCS #
#######

# make bin/occamy_top.vsim
# CC=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/gcc
# CXX=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/g++
# LD=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/ld
bin/occamy_top.vcs: work-vcs/compile.sh work/lib/libfesvr.a ${TB_CC_SOURCES} test/bootrom.bin
	mkdir -p bin
	vcs $(VCS_FLAGS) -o bin/occamy_top.vcs tb_bin -cc $(CC) -cpp $(CXX) \
		$(TB_CC_SOURCES) -CFLAGS "$(TB_CC_FLAGS)" -LDFLAGS "-L${FESVR}/lib" -lfesvr -lutil

.PHONY: clean-vcs
clean-vcs:
	rm -rf AN.DB
	rm -rf work-vcs
	rm -f bin/occamy_top.vcs

########
# FPGA #
########

fpga:
	${MAKE} -C fpga occamy_vcu128

.PHONY: fpga
