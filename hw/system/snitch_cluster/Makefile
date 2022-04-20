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

VLOG_FLAGS 	  += -svinputport=compat
VLOG_FLAGS 	  += -override_timescale 1ns/1ps
VLOG_FLAGS 	  += -suppress 2583
VLOG_FLAGS 	  += -suppress 13314
VLOG_FLAGS 	  += ${QUESTA_64BIT}

app_path 		?= $(ROOT)/sw/riscv-tests/isa
buildpath 	?= build
resultpath 	?= result
$(buildpath):
	mkdir -p $(buildpath)
$(resultpath):
	mkdir -p $(resultpath)
TESTS_DIR ?= $(ROOT)/sw/riscv-tests/isa
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
bin/snitch_cluster.vlt: $(VLT_AR) $(VLT_COBJ) ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) -std=c++14 -L ${VLT_BUILDDIR}/lib -o $@ $(VLT_COBJ) $(VLT_AR) -lfesvr -lpthread

############
# Modelsim #
############
${VSIM_BUILDDIR}/compile.vsim.tcl: $(VSIM_SOURCES) ${TB_SRCS} ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc
	vlib $(dir $@)
	${BENDER} script vsim ${VSIM_BENDER} --vlog-arg="${VLOG_FLAGS} -work $(dir $@) " > $@
	echo '${VLOG} -work $(dir $@) ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc -ccflags "-std=c++14 -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR}"' >> $@
	echo 'return 0' >> $@

bin/snitch_cluster.vsim: ${VSIM_BUILDDIR}/compile.vsim.tcl work/lib/libfesvr.a
	$(call QUESTASIM,tb_bin)

#######
# VCS #
#######
bin/snitch_cluster.vcs: work-vcs/compile.sh work/lib/libfesvr.a generated/snitch_cluster_wrapper.sv ${TB_DIR}/common_lib.cc generated/bootdata.cc
	mkdir -p bin
	vcs -Mlib=work-vcs -Mdir=work-vcs -o bin/snitch_cluster.vcs -cc $(CC) -cpp $(CXX) \
		-assert disable_cover -override_timescale=1ns/1ps -full64 tb_bin ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc \
		-CFLAGS "-std=c++14 -I${MKFILE_DIR} -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR}" -LDFLAGS "-L${FESVR}/lib" -lfesvr

######
# SW #
######
# VSIM
sw/build.vsim: clean-sw
	mkdir -p sw/build
	cd sw/build && cmake-3.18.1 -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm -DSNITCH_SIMULATOR=../../../../../hw/system/snitch_cluster/bin/snitch_cluster.vsim -DBUILD_TESTS=ON .. && make

sw/test.vsim: sw/build.vsim
	cd sw/build && make test

# VLT
sw/build.vlt: clean-sw
	mkdir -p sw/build
	cd sw/build && cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm -DBUILD_TESTS=ON .. && make

sw/test.vlt: sw/build.vlt
	cd sw/build && make test

# Clean
clean-sw:
	rm -rf sw/build

############################
# Unit tests simulation    #
############################

test_bin := ../../../sw/riscv-tests/isa
sim_test: $(test)
test:
	echo "${test_bin}/rv32uxpulpimg-p-p_abs > logs/.rtlbinary"
	vsim -64 +permissive -work /scratch/msc22f9/snitch/hw/system/snitch_cluster//work-vsim -c -ldflags "-Wl,-rpath,/scratch/msc22f9/snitch/hw/system/snitch_cluster/work/lib -L/scratch/msc22f9/snitch/hw/system/snitch_cluster/work/lib -lfesvr -lutil" -t 1ps -voptargs=+acc tb_bin +permissive-off ++${test_bin}/rv32uxpulpimg-p-p_abs -do "log -r /*; run -a"
	echo "${test_bin}/rv32uxpulpimg-p-p_abs > logs/.rtlbinary"

#########
# Phony #
#########
clean:
	rm -rf ${VLT_BUILDDIR} Bender.lock .bender/
	# work/

.PHONY: clean vlt.build vsim.build all
