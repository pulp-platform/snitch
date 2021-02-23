# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../..

VSIM_BENDER   += -t test -t rtl -t simulation -t vsim
VSIM_SOURCES  := $(shell ${BENDER} script flist ${VSIM_BENDER} | ${SED_SRCS})

include $(ROOT)/util/Makefrag

${VLT_BUILDDIR}/verilate: ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,occamy_top)

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

bin/snitch_cluster.vcs: work-vcs/compile.sh
	mkdir -p bin
	vcs -Mlib=work-vcs -Mdir=work-vcs -o bin/occamy_quadrant_s1.vcs  \
		-assert disable_cover -override_timescale=1ns/1ps -full64 occamy_top

