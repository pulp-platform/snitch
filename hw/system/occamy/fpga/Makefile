# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../../..

VIVADO := vivado

include $(ROOT)/util/Makefrag

vivado_ips/occamy_xilinx:
	${MAKE} -C vivado_ips occamy_xilinx

bootrom/bootrom.coe:
	${MAKE} -C bootrom bootrom.coe

occamy_vcu128: vivado_ips/occamy_xilinx define_defines_includes_no_simset.tcl bootrom/bootrom.coe
	${VIVADO} -source occamy_vcu128.tcl

define_defines_includes_no_simset.tcl: $(BENDER_FILES)
	${BENDER} script vivado --only-defines --only-includes --no-simset > $@

clean:
	${MAKE} -C vivado_ips clean
	rm -rf .Xil occamy_vcu128 define_defines_includes_no_simset.tcl *.jou *.log *.str
