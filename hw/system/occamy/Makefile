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

QUESTA_64BIT	= -64
VSIM      		= vsim ${QUESTA_64BIT}
VLOG      		= vlog ${QUESTA_64BIT}

VLOG_FLAGS 	  += -svinputport=compat
VLOG_FLAGS 	  += -override_timescale 1ns/1ps
VLOG_FLAGS 	  += -suppress 2583
VLOG_FLAGS 	  += -suppress 13314
VLOG_FLAGS 	  += ${QUESTA_64BIT}

all: update-source update-plic update-socreg

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
	@$(ROOT)/util/occamygen.py --cfg src/occamy_cfg.hjson --graph addrmap.dot --outdir . \
		--dts test/occamy.dts \
		src/occamy_top.sv \
		src/occamy_pkg.sv \
		src/occamy_quadrant_s1.sv \
		src/occamy_xilinx.sv \
		test/testharness.sv \
		src/occamy_cva6.sv
	@echo "[VERIBLE] Formatting"
	@verible-verilog-format --inplace src/occamy_quadrant_s1.sv src/occamy_pkg.sv src/occamy_top.sv src/occamy_xilinx.sv src/occamy_cva6.sv

update-plic:
	mkdir -p src/rv_plic
	$(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/util/reg_rv_plic.py -s 58 -t 2 -p 6 $(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/data/rv_plic.sv.tpl > src/rv_plic/rv_plic.sv
	$(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/util/reg_rv_plic.py -s 58 -t 2 -p 6 $(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/data/rv_plic.hjson.tpl > src/rv_plic/rv_plic.hjson
	$(ROOT)/util/regtool.py -r -t src/rv_plic src/rv_plic/rv_plic.hjson

# Regenerate the SoC register.
update-socreg: src/occamy_soc_reg/occamy_soc_reg.hjson
	$(REGGEN) -r src/occamy_soc_reg/occamy_soc_reg.hjson --outdir src/occamy_soc_reg/

addrmap.png: update-source
	dot -Tpng addrmap.dot > addrmap.png

#############
# Verilator #
#############
${VLT_BUILDDIR}/verilate: ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,occamy_top)

# Quick sanity check, not really meant for simulation.
verilate: ${VLT_BUILDDIR}/verilate

############
# Modelsim #
############
${VSIM_BUILDDIR}/compile.vsim.tcl: $(VSIM_SOURCES) ${TB_SRCS} ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc test/bootdata.cc test/bootrom.bin
	vlib $(dir $@)
	${BENDER} script vsim ${VSIM_BENDER} --vlog-arg="${VLOG_FLAGS} -work $(dir $@) " > $@
	echo '${VLOG} -work $(dir $@) ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc test/bootdata.cc -ccflags "-std=c++14 -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR}"' >> $@
	echo '${VLOG} -work $(dir $@) test/uartdpi/uartdpi.c -ccflags "-Itest/uartdpi"' >> $@
	echo 'return 0' >> $@

bin/occamy_top.vsim: ${VSIM_BUILDDIR}/compile.vsim.tcl work/lib/libfesvr.a
	$(call QUESTASIM)

#######
# VCS #
#######
# make bin/occamy_top.vsim
# CC=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/gcc
# CXX=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/g++
# LD=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/ld
bin/occamy_top.vcs: work-vcs/compile.sh work/lib/libfesvr.a ${TB_DIR}/common_lib.cc test/bootdata.cc test/bootrom.bin test/uartdpi/uartdpi.c
	mkdir -p bin
	vcs -Mlib=work-vcs -Mdir=work-vcs -debug_access+all -fgp -kdb +vcs+fsdbon -o bin/occamy_top.vcs -cc $(CC) -cpp $(CXX) \
		-assert disable_cover -override_timescale=1ns/1ps -full64 tb_bin ${TB_DIR}/rtl_lib.cc ${TB_DIR}/common_lib.cc test/bootdata.cc test/uartdpi/uartdpi.c \
		-CFLAGS "-std=c++14 -I${MKFILE_DIR} -I${MKFILE_DIR}/test -I${FESVR}/include -I${TB_DIR} -Itest/uartdpi" -LDFLAGS "-L${FESVR}/lib" -lfesvr -lutil

########
# FPGA #
########
fpga:
	${MAKE} -C fpga occamy_vcu128

.PHONY: fpga
