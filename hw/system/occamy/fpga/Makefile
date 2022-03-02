# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../../..
ARIANE_SDK  ?= ${ROOT}/../ariane-sdk
DEBUG       ?= 0
VCU         ?= 01
FPGA_ID     := 091847100576A

# Select VCU128-02
ifeq ($(VCU),02)
	FPGA_ID := 091847100638A
endif

VIVADO := vivado

include $(ROOT)/util/Makefrag

vivado_ips/occamy_xilinx:
	${MAKE} -C vivado_ips occamy_xilinx

bootrom/bootrom-spl.coe:
	${MAKE} -C bootrom

occamy_vcu128: vivado_ips/occamy_xilinx define_defines_includes_no_simset.tcl bootrom/bootrom-spl.coe
	${VIVADO} -mode batch -source occamy_vcu128.tcl -tclargs $(DEBUG)

define_defines_includes_no_simset.tcl: $(BENDER_FILES)
	${BENDER} script vivado --only-defines --only-includes --no-simset > $@

program:
	${VIVADO} -mode batch -source occamy_vcu128_program.tcl -tclargs $(FPGA_ID)

flash: ${FILE}
	${VIVADO} -mode batch -source occamy_vcu128_flash.tcl -tclargs ${FPGA_ID} ${FILE} ${OFFSET}
	rm data.mcs

flash-u-boot:
	${MAKE} flash FILE=${ARIANE_SDK}/u-boot/u-boot.itb OFFSET=0x6000000

flash-uimage:
	${MAKE} flash FILE=${ARIANE_SDK}/uImage OFFSET=0x6100000

clean:
	${MAKE} -C vivado_ips clean
	rm -rf .Xil occamy_vcu128 define_defines_includes_no_simset.tcl *.jou *.log *.str

.PHONY: program flash clean
