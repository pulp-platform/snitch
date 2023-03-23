# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../..

include $(ROOT)/util/Makefrag

VLT_FLAGS 	  += -Wno-SYMRSVDWORD
REGGEN        ?= ${ROOT}/util/regtool.py
CLANG_FORMAT  ?= $(shell which clang-format-10.0.1)

QUESTA_64BIT	= -64
VSIM      		= vsim ${QUESTA_64BIT}
VLOG      		= vlog ${QUESTA_64BIT}

VSIM_FLAGS    += -t 1ps
VSIM_FLAGS    += -voptargs=+acc
VSIM_FLAGS    += -do "log -r /*; run -a"
# Downgraded from error as VSIM *wrongly* reports illegal enum assignments in riscv_dbg 4-phase CDCs
# TODO: Workaround; revise
VSIM_FLAGS    += -warning 8386

VLOG_FLAGS 	  += -svinputport=compat
VLOG_FLAGS 	  += -override_timescale 1ns/1ps
VLOG_FLAGS 	  += -suppress 2583
VLOG_FLAGS 	  += -suppress 13314
VLOG_FLAGS 	  += ${QUESTA_64BIT}

CFG ?= src/occamy_cfg.hjson
REG_INCDIR ?= ${ROOT}/sw/snRuntime/include/

all: update-clint update-plic update-socreg update-quadreg update-source update-addrmap

test: ${VSIM_SOURCES} ${TB_SRCS}
	echo ${VSIM_SOURCES}
	touch test

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
update-source:
	@echo "[SOLDER]  Generating sources"
	@echo "[SOLDER]  RTL"
	@$(ROOT)/util/occamygen.py --cfg $(CFG) --graph addrmap/addrmap.dot --outdir src --wrapper --memories \
		--top-sv src/occamy_top.sv.tpl \
		--soc-sv src/occamy_soc.sv.tpl \
		--pkg-sv src/occamy_pkg.sv.tpl \
		--quadrant-s1 src/occamy_quadrant_s1.sv.tpl \
		--quadrant-s1-ctrl src/occamy_quadrant_s1_ctrl.sv.tpl \
		--xilinx-sv src/occamy_xilinx.sv.tpl \
		--cva6-sv src/occamy_cva6.sv.tpl
	@$(ROOT)/util/occamygen.py --cfg $(CFG) --graph addrmap/addrmap.dot --am-csv addrmap/addrmap.csv --am-cheader $(REG_INCDIR)/occamy_base_addr.h \
		--outdir test \
		--testharness-sv test/testharness.sv.tpl \
		--bootdata ../../ip/snitch_cluster/test/bootdata.cc.tpl
	@echo "[SOLDER]  Device Tree"
	@$(ROOT)/util/occamygen.py --cfg $(CFG) --outdir . --dts test/occamy.dts
	@echo "[VERIBLE] Formatting"
	@verible-verilog-format --inplace src/occamy_quadrant_s1.sv src/occamy_pkg.sv src/occamy_soc.sv src/occamy_top.sv src/occamy_xilinx.sv src/occamy_cva6.sv

CLINTROOT = $(ROOT)/hw/vendor/pulp_platform_clint
update-clint:
	@mkdir -p src/clint
	@echo "[SOLDER]  Generate CLINT config"
	@$(ROOT)/util/occamygen.py --cfg $(CFG) --outdir src/clint --chip $(CLINTROOT)/data/clint.hjson.tpl
	@$(ROOT)/util/occamygen.py --cfg $(CFG) --outdir src/clint --chip $(CLINTROOT)/data/clint.sv.tpl
	@echo "[REGGEN]  Generate CLINT regs"
	@$(ROOT)/util/regtool.py -r -t src/clint src/clint/clint.hjson

PLICSRC = $(ROOT)/hw/vendor/pulp_platform_opentitan_peripherals/src/rv_plic
update-plic:
	@mkdir -p src/rv_plic
	@echo "[PLICGEN] Generate PLIC config"
	@$(PLICSRC)/util/reg_rv_plic.py -s 73 -t 2 -p 6 $(PLICSRC)/data/rv_plic.sv.tpl > src/rv_plic/rv_plic.sv
	@$(PLICSRC)/util/reg_rv_plic.py -s 73 -t 2 -p 6 $(PLICSRC)/data/rv_plic.hjson.tpl > src/rv_plic/rv_plic.hjson
	@echo "[REGGEN]  Generate PLIC regs"
	@$(ROOT)/util/regtool.py -r -t src/rv_plic src/rv_plic/rv_plic.hjson

# Update generic control register.
# $1: config name, $2: output directory, $3: output filename stem, $4: header filename stem
define update_ctrl_regs
	$(if $5, @echo "[REGGEN]  Generate $1 config" && \
		$(ROOT)/util/occamygen.py --cfg $(CFG) --outdir $2 --chip $2/$3.tpl)
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

## Generate the addressmap in the following formats: MD, TEX
update-addrmap: addrmap.tex addrmap.md

## Generate the addressmap in the following formats: MD, PNG, TEX, PDF
addrmap: update-source update-addrmap addrmap.png addrmap.pdf

addrmap.png: update-source
	dot -Tpng addrmap/addrmap.dot > addrmap/addrmap.png

## Generate the TEX addrmap source
addrmap.tex: update-source
	@$(ROOT)/util/addrmapgen.py --file addrmap/addrmap.csv --outdir addrmap --tex addrmap/addrmap.tex.tpl

## Generate the MD addrmap graphic
addrmap.md: update-source
	@$(ROOT)/util/addrmapgen.py --file addrmap/addrmap.csv --outdir docs --md 2_addrmap.md

## Generate the PDF addrmap graphic
addrmap.pdf: addrmap.tex
	cd addrmap && latexmk -quiet -pdf addrmap.tex

## Delete all Latex outputs when generating the addrmap.pdf from addrmap.tex
clean.addrmap.pdf:
	rm -rf addrmap/addrmap.aux
	rm -rf addrmap/addrmap.fdb*
	rm -rf addrmap/addrmap.fls
	rm -rf addrmap/addrmap.log
	rm -rf addrmap/addrmap.pdf

## Delete the Latex output addrmap.pdf
clean.addrmap: clean.addrmap.pdf
	rm -rf addrmap.png


#############
# Verilator #
#############
${VLT_BUILDDIR}/verilate: ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,occamy_top)

# Quick sanity check, not really meant for simulation.
verilate: ${VLT_BUILDDIR}/verilate

## Clean all build directories and temporary files for Verilator simulation
clean.vlt:
	rm -rf ${VLT_BUILDDIR} work


############
# Modelsim #
############
${VSIM_BUILDDIR}/compile.vsim.tcl: $(VSIM_SOURCES) ${TB_SRCS} ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc test/bootdata.cc test/bootrom.bin
	vlib $(dir $@)
	${BENDER} script vsim ${VSIM_BENDER} --vlog-arg="${VLOG_FLAGS} -work $(dir $@) " > $@
	echo '${VLOG} -work $(dir $@) ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc test/bootdata.cc -ccflags "-std=c++14 -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR}"' >> $@
	echo '${VLOG} -work $(dir $@) test/uartdpi/uartdpi.c -ccflags "-Itest/uartdpi"' >> $@
	echo 'return 0' >> $@

# @IIS:
# CC=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/gcc
# CXX=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/g++
# LD=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/ld
# make bin/occamy_top.vsim
## Build compilation script and compile all sources for Questasim simulation
bin/occamy_top.vsim: ${VSIM_BUILDDIR}/compile.vsim.tcl work/lib/libfesvr.a
	$(call QUESTASIM,tb_bin)

## Clean all build directories and temporary files for Questasim simulation
clean.vsim:
	rm -rf bin/occamy_top.vsim bin/occamy_top.vsim.gui work-vsim work vsim.wlf


#######
# VCS #
#######
# @IIS: vcs-2020.12 make bin/occamy_top.vcs
## Build compilation script and compile all sources for VCS simulation
bin/occamy_top.vcs: work-vcs/compile.sh work/lib/libfesvr.a ${TB_DIR}/common_lib.cc test/bootdata.cc test/bootrom.bin test/uartdpi/uartdpi.c
	mkdir -p bin
	vcs -Mlib=work-vcs -Mdir=work-vcs -debug_access+all -fgp -kdb +vcs+fsdbon -o bin/occamy_top.vcs -cc $(CC) -cpp $(CXX) \
		-assert disable_cover -override_timescale=1ns/1ps -full64 tb_bin ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc test/bootdata.cc test/uartdpi/uartdpi.c \
		-CFLAGS "-std=c++14 -I${MKFILE_DIR} -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR} -Itest/uartdpi" -LDFLAGS "-L${FESVR}/lib" -lfesvr -lutil

## Clean all build directories and temporary files for VCS simulation
clean.vcs:
	rm -rf bin/occamy_top.vcs work-vcs work


######
# SW #
######
## Build SW into sw/build with the LLVM toolchain
sw: clean.sw
	mkdir -p sw/build
	cd sw/build && cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm && make

# VSIM
## Build SW into sw/build with the LLVM toolchain (including tests) for Questasim simulator
sw.vsim: clean.sw
	mkdir -p sw/build
	cd sw/build && cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm -DSNITCH_SIMULATOR=../../../../../hw/system/occamy/bin/occamy_top.vsim -DBUILD_TESTS=ON .. && make

## Build SW and run all tests with Questasim simulator
sw.test.vsim: sw.vsim
	cd sw/build && make test

# VCS
## Build SW into sw/build with the LLVM toolchain (including tests) for VCS simulator
sw.vcs: clean.sw
	mkdir -p sw/build
	cd sw/build && cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm -DSNITCH_SIMULATOR=../../../../../hw/system/occamy/bin/occamy_top.vcs -DBUILD_TESTS=ON .. && make

## Build SW and run all tests with VCS simulator
sw.test.vcs: sw.vcs
	cd sw/build && make test

# VLT
## Build SW into sw/build with the LLVM toolchain (including tests) for Verilator simulator
sw.vlt: clean.sw
	mkdir -p sw/build
	cd sw/build && cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm -DBUILD_TESTS=ON .. && make

## Build SW and run all tests with Verilator simulator
sw.test.vlt: sw.vlt
	cd sw/build && make test

## Delete sw/build
clean.sw:
	rm -rf sw/build


########
# FPGA #
########
## Build a small Occamy version (CVA6 + 1xcluster) for the VCU128 FPGA board
fpga:
	${MAKE} -C fpga occamy_vcu128

.PHONY: fpga


########
# Util #
########

## Clean everything except logs
clean: clean.vcs clean.vlt clean.vsim clean.sw
	rm -rf Bender.lock .bender/ work/

clean.logs:
	rm -rf logs/

## Help command
.DEFAULT_GOAL := help
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
	@echo -e "${Blue}update-addrmap ${Black}Generate the addressmap in the following formats: MD, TEX."
	@echo -e "${Blue}addrmap        ${Black}Generate the addressmap in the following formats: MD, PNG, TEX, PDF."
	@echo -e "${Blue}addrmap.tex    ${Black}Generate the TEX addrmap source."
	@echo -e "${Blue}addrmap.md     ${Black}Generate the MD addrmap graphic."
	@echo -e "${Blue}addrmap.png    ${Black}Generate the PNG addrmap graphic."
	@echo -e "${Blue}addrmap.pdf    ${Black}Generate the PDF addrmap graphic."
	@echo -e ""
	@echo -e "${Blue}clean          ${Black}Clean everything except traces in logs directory."
	@echo -e "${Blue}clean.sw       ${Black}Delete sw/build."
	@echo -e "${Blue}clean.addrmap  ${Black}Delete all addrmap outputs."
	@echo -e "${Blue}clean.addrmap.pdf ${Black}Delete all Latex outputs when generating the addrmap.pdf from addrmap.tex"
	@echo -e "${Blue}clean.logs     ${Black}Delete all traces in logs directory."
	@echo -e "${Blue}clean.vcs      ${Black}Clean all build directories and temporary files for VCS simulation."
	@echo -e "${Blue}clean.vlt      ${Black}Clean all build directories and temporary files for Verilator simulation."
	@echo -e "${Blue}clean.vsim     ${Black}Clean all build directories and temporary files for Questasim simulation."
	@echo -e ""
	@echo -e "${Blue}sw             ${Black}Build SW into sw/build with the LLVM."
	@echo -e "${Blue}sw.vcs         ${Black}Build SW into sw/build with the LLVM (incl. tests) for VCS simulator."
	@echo -e "${Blue}sw.vlt         ${Black}Build SW into sw/build with the LLVM (incl. tests) for Verilator simulator."
	@echo -e "${Blue}sw.vsim        ${Black}Build SW into sw/build with the LLVM (incl. tests) for Questasim simulator."
	@echo -e ""
	@echo -e "${Blue}sw.test.vcs    ${Black}Build SW and run all tests with VCS simulator."
	@echo -e "${Blue}sw.test.vlt    ${Black}Build SW and run all tests with Verilator simulator."
	@echo -e "${Blue}sw.test.vsim   ${Black}Build SW and run all tests with Questasim simulator."
	@echo -e ""
	@echo -e "Additional useful targets from the included Makefrag:"
	@echo -e "${Blue}traces         ${Black}Generate the better readable traces in .logs/trace_hart_<hart_id>.txt with spike-dasm."
	@echo -e "${Blue}annotate       ${Black}Annotate the better readable traces in .logs/trace_hart_<hart_id>.s with the source code related with the retired instructions."
