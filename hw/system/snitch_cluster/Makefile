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
${VLT_BUILDDIR}/verilate: ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,testharness)

verilate: ${VLT_BUILDDIR}/verilate

bin/snitch_cluster.vlt: ${VLT_BUILDDIR}/verilate ${TB_DIR}/verilator_lib.cc ${TB_DIR}/common_lib.cc ${TB_DIR}/tb_bin.cc work/lib/libfesvr.a test/bootrom.bin generated/bootdata.cc
	$(CXX) $(VLT_CFLAGS) -c ${TB_DIR}/common_lib.cc -o ${VLT_BUILDDIR}/common_lib.o -Itest
	$(CXX) $(VLT_CFLAGS) -c generated/bootdata.cc -o ${VLT_BUILDDIR}/bootdata.o -Itest
	$(CXX) $(VLT_CFLAGS) -c ${TB_DIR}/verilator_lib.cc -o ${VLT_BUILDDIR}/verilator_lib.o
	$(CXX) $(VLT_CFLAGS) -c $(VLT_ROOT)/include/verilated.cpp -o ${VLT_BUILDDIR}/verilated.o
	$(CXX) $(VLT_CFLAGS) -c $(VLT_ROOT)/include/verilated_dpi.cpp -o ${VLT_BUILDDIR}/verilated_dpi.o
	$(CXX) $(VLT_CFLAGS) -c $(VLT_ROOT)/include/verilated_vcd_c.cpp -o ${VLT_BUILDDIR}/verilated_vcd_c.o
	mkdir -p bin
	$(LD) -o ${VLT_BUILDDIR}/snitch_cluster.o -r \
		${VLT_BUILDDIR}/common_lib.o \
		${VLT_BUILDDIR}/bootdata.o \
		${VLT_BUILDDIR}/verilator_lib.o \
		${VLT_BUILDDIR}/verilated.o \
		${VLT_BUILDDIR}/verilated_dpi.o \
		${VLT_BUILDDIR}/verilated_vcd_c.o \
		${VLT_BUILDDIR}/Vtestharness__ALL.a \
		-lfesvr \
		-L ${VLT_BUILDDIR} \
		-L $(FESVR)/lib
	$(AR) rcs bin/libsnitch_cluster.a ${VLT_BUILDDIR}/snitch_cluster.o
	$(CXX) $(VLT_CFLAGS) ${TB_DIR}/tb_bin.cc -L bin -lsnitch_cluster -o $@

############
# Modelsim #
############
${VSIM_BUILDDIR}/compile.vsim.tcl: $(VSIM_SOURCES) ${TB_SRCS} ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc
	vlib $(dir $@)
	${BENDER} script vsim ${VSIM_BENDER} --vlog-arg="${VLOG_FLAGS} -work $(dir $@) " > $@
	echo '${VLOG} -work $(dir $@) ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc -ccflags "-std=c++14 -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR}"' >> $@
	echo 'return 0' >> $@

bin/snitch_cluster.vsim: ${VSIM_BUILDDIR}/compile.vsim.tcl work/lib/libfesvr.a
	$(call QUESTASIM)

#######
# VCS #
#######
bin/snitch_cluster.vcs: work-vcs/compile.sh work/lib/libfesvr.a generated/snitch_cluster_wrapper.sv ${TB_DIR}/common_lib.cc generated/bootdata.cc
	mkdir -p bin
	vcs -Mlib=work-vcs -Mdir=work-vcs -o bin/snitch_cluster.vcs -cc $(CC) -cpp $(CXX) \
		-assert disable_cover -override_timescale=1ns/1ps -full64 tb_bin ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc generated/bootdata.cc \
		-CFLAGS "-std=c++14 -I${MKFILE_DIR} -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR}" -LDFLAGS "-L${FESVR}/lib" -lfesvr

#########
# Phony #
#########
clean:
	rm -rf ${VLT_BUILDDIR} Bender.lock .bender/
	# work/

.PHONY: clean vlt.build vsim.build all
