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
VSIM_BENDER   += -t test -t rtl -t simulation -t vsim
VSIM_SOURCES  := $(shell ${BENDER} script flist ${VSIM_BENDER} | ${SED_SRCS})
REGGEN        ?= ${ROOT}/util/regtool.py

${VLT_BUILDDIR}/verilate: ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,occamy_top)

##########
# Source #
##########
update-source:
	$(ROOT)/util/occamygen.py --clustercfg src/occamy_cluster_cfg.hjson --graph addrmap.dot --outdir . src/occamy_top.sv src/occamy_pkg.sv src/occamy_quadrant_s1.sv src/occamy_xilinx.sv
	dot -Tpng addrmap.dot > addrmap.png
	verible-verilog-format --inplace src/occamy_quadrant_s1.sv src/occamy_pkg.sv src/occamy_top.sv src/occamy_xilinx.sv

update-plic:
	mkdir -p src/rv_plic
	$(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/util/reg_rv_plic.py -s 10 -t 2 -p 6 $(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/data/rv_plic.sv.tpl > src/rv_plic/rv_plic.sv
	$(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/util/reg_rv_plic.py -s 10 -t 2 -p 6 $(ROOT)/hw/vendor/lowrisc_opentitan/rv_plic/data/rv_plic.hjson.tpl > src/rv_plic/rv_plic.hjson
	$(ROOT)/util/regtool.py -r -t src/rv_plic src/rv_plic/rv_plic.hjson

# Regenerate the SoC register.
update-socreg: src/occamy_soc_reg/occamy_soc_reg.hjson
	$(REGGEN) -r src/occamy_soc_reg/occamy_soc_reg.hjson --outdir src/occamy_soc_reg/

#############
# Verilator #
#############
verilate: ${VLT_BUILDDIR}/verilate

#######
# VCS #
#######
work-vcs/compile.sh: $(VSIM_SOURCES) ${TB_SRCS}
	mkdir -p work-vcs
	${BENDER} script vcs ${VSIM_BENDER} --vlog-arg="-assert svaext -assert disable_cover" > $@
	chmod +x $@
	$@

bin/occamy_top.vcs: work-vcs/compile.sh
	mkdir -p bin
	vcs -Mlib=work-vcs -Mdir=work-vcs -o bin/occamy_top.vcs  \
		-assert disable_cover -override_timescale=1ns/1ps -full64 occamy_top

