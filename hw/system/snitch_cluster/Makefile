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

CFG 		?= cfg/cluster.default.hjson
CLUSTER_GEN ?= $(ROOT)/util/clustergen.py
CLUSTER_GEN_SRC ?= $(wildcard $(ROOT)/util/clustergen/*.py)

# Verilated and compiled snitch cluster
VLT_AR          = ${VLT_BUILDDIR}/Vtestharness__ALL.a

# uncomment, if questasim should be run in 64-bit mode
QUESTA_64BIT	= -64
VSIM      		= vsim ${QUESTA_64BIT}
VLOG      		= vlog ${QUESTA_64BIT}

VLT_FLAGS    += --trace

VSIM_FLAGS    += -t 1ps
VSIM_FLAGS    += -voptargs=+acc
VSIM_FLAGS    += -do "log -r /*; run -a"

VLOG_FLAGS 	  += -svinputport=compat
VLOG_FLAGS 	  += -override_timescale 1ns/1ps
VLOG_FLAGS 	  += -suppress 2583
VLOG_FLAGS 	  += -suppress 13314
VLOG_FLAGS 	  += ${QUESTA_64BIT}

#######
# RTL #
#######
${MKFILE_DIR}generated/snitch_cluster_wrapper.sv: ${CFG} ${CLUSTER_GEN} ${CLUSTER_GEN_SRC}
	$(CLUSTER_GEN) -c $< -o .

#################
# Prerequisites #
#################
test/bootrom.elf test/bootrom.dump test/bootrom.bin: test/bootrom.S test/bootrom.ld
	riscv64-unknown-elf-gcc -mabi=ilp32d -march=rv32imafd -static -nostartfiles -Ttest/bootrom.ld $< -o test/bootrom.elf
	riscv64-unknown-elf-objdump -d test/bootrom.elf > test/bootrom.dump
	riscv64-unknown-elf-objcopy -j .text -O binary test/bootrom.elf test/bootrom.bin

#############
# Verilator #
#############
$(VLT_AR): ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,testharness)
verilate: $(VLT_AR)

# Required C sources for the verilator TB that are linked against the verilated model
VLT_COBJ += $(VLT_BUILDDIR)/tb/common_lib.o
VLT_COBJ += $(VLT_BUILDDIR)/tb/verilator_lib.o
VLT_COBJ += $(VLT_BUILDDIR)/tb/tb_bin.o
# Sources from verilator root
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated.o
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated_dpi.o
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated_vcd_c.o
# Bootdata
VLT_COBJ += $(VLT_BUILDDIR)/generated/bootdata.o

clean-vlt-obj:
	rm $(VLT_COBJ)

# Build targets for verilator TB
$(VLT_BUILDDIR)/tb/%.o: $(TB_DIR)/%.cc $(VLT_AR) ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@
$(VLT_BUILDDIR)/vlt/%.o: $(VLT_ROOT)/include/%.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@
$(VLT_BUILDDIR)/generated/%.o: generated/%.cc ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@

# Link verilated archive wich $(VLT_COBJ)
## Build compilation script and compile all sources for Verilator simulation
bin/snitch_cluster.vlt: $(VLT_AR) $(VLT_COBJ) ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) -std=c++14 -L ${VLT_BUILDDIR}/lib -o $@ $(VLT_COBJ) $(VLT_AR) -lfesvr -lpthread

## Clean all build directories and temporary files for Verilator simulation
clean.vlt:
	rm -rf ${VLT_BUILDDIR} work

############
# Modelsim #
############
${VSIM_BUILDDIR}/compile.vsim.tcl: $(VSIM_SOURCES) ${TB_SRCS} ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc
	vlib $(dir $@)
	${BENDER} script vsim ${VSIM_BENDER} --vlog-arg="${VLOG_FLAGS} -work $(dir $@) " > $@
	echo '${VLOG} -work $(dir $@) ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc -ccflags "-std=c++14 -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR}"' >> $@
	echo 'return 0' >> $@

## Build compilation script and compile all sources for Questasim simulation
bin/snitch_cluster.vsim: ${VSIM_BUILDDIR}/compile.vsim.tcl work/lib/libfesvr.a
	$(call QUESTASIM,tb_bin)

## Clean all build directories and temporary files for Questasim simulation
clean.vsim:
	rm -rf bin/snitch_cluster.vsim bin/snitch_cluster.vsim.gui work-vsim work vsim.wlf

#######
# VCS #
#######
## Build compilation script and compile all sources for VCS simulation
bin/snitch_cluster.vcs: work-vcs/compile.sh work/lib/libfesvr.a generated/snitch_cluster_wrapper.sv ${TB_DIR}/common_lib.cc generated/bootdata.cc
	mkdir -p bin
	vcs -Mlib=work-vcs -Mdir=work-vcs -o bin/snitch_cluster.vcs -cc $(CC) -cpp $(CXX) \
		-assert disable_cover -override_timescale=1ns/1ps -full64 tb_bin ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc \
		-CFLAGS "-std=c++14 -I${MKFILE_DIR} -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR}" -LDFLAGS "-L${FESVR}/lib" -lfesvr

## Clean all build directories and temporary files for VCS simulation
clean.vcs:
	rm -rf bin/snitch_cluster.vcs work-vcs work

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
	cd sw/build && cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm -DSNITCH_SIMULATOR=../../../../../hw/system/snitch_cluster/bin/snitch_cluster.vsim -DBUILD_TESTS=ON .. && make

## Build SW and run all tests with Questasim simulator
sw.test.vsim: sw.vsim
	cd sw/build && make test

# VCS
## Build SW into sw/build with the LLVM toolchain (including tests) for VCS simulator
sw.vcs: clean.sw
	mkdir -p sw/build
	cd sw/build && cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm -DSNITCH_SIMULATOR=../../../../../hw/system/snitch_cluster/bin/snitch_cluster.vcs -DBUILD_TESTS=ON .. && make

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
# Util #
########
.PHONY: help clean vlt.build vsim.build all
.DEFAULT_GOAL := help

## Clean everything
clean: clean.vcs clean.vlt clean.vsim clean.sw
	rm -rf Bender.lock .bender/ work/

clean.logs:
	rm -rf logs/

## Help command
Blue=\033[1;34m
Black=\033[0m
help:
	@echo -e "${Blue}Makefile Targets${Black} for the ${Blue}Snitch Cluster${Black}"
	@echo -e "Use 'make <target>' where <target> is one of:"
	@echo -e ""
	@echo -e "${Blue}help           ${Black}Show an overview of all Makefile targets."
	@echo -e ""
	@echo -e "${Blue}bin/snitch_cluster.vcs  ${Black}Build compilation script and compile all sources for VCS simulation."
	@echo -e "${Blue}bin/snitch_cluster.vlt  ${Black}Build compilation script and compile all sources for Verilator simulation."
	@echo -e "${Blue}bin/snitch_cluster.vsim ${Black}Build compilation script and compile all sources for Questasim simulation."
	@echo -e ""
	@echo -e "${Blue}clean          ${Black}Clean everything except traces in logs directory."
	@echo -e "${Blue}clean.sw       ${Black}Delete sw/build."
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
