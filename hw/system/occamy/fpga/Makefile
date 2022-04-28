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

VIVADO ?= vivado
NPROC  ?= $(shell nproc)

default: all
all: occamy_vcu128

include $(ROOT)/util/Makefrag

# Clone a repo or pull if it exists
# Args: path, repo, branch
define clone
if [ ! -d "$1" ]; then \
  git clone --depth 1 --branch $3 $2 $1; \
else \
  git fetch -a; \
	git pull ; \
fi
endef

vivado_ips/occamy_xilinx:
	${MAKE} -C vivado_ips occamy_xilinx

bootrom/bootrom-spl.coe:
	${MAKE} -C bootrom

occamy_vcu128: vivado_ips/occamy_xilinx bootrom/bootrom-spl.coe
	${VIVADO} -mode batch -source occamy_vcu128.tcl -tclargs $(DEBUG) $(NPROC) ${MKFILE_DIR}/bootrom/bootrom-spl.coe

program:
	${VIVADO} -mode batch -source occamy_vcu128_program.tcl -tclargs $(FPGA_ID)

flash: ${FILE}
	${VIVADO} -mode batch -source occamy_vcu128_flash.tcl -tclargs ${FPGA_ID} ${FILE} ${OFFSET}
	rm data.mcs

flash-u-boot:
	${MAKE} flash FILE=${ARIANE_SDK}/u-boot/u-boot.itb OFFSET=0x6000000

flash-uimage:
	${MAKE} flash FILE=${ARIANE_SDK}/uImage OFFSET=0x6100000

.PHONY: br-hrv-vcu128
br-hrv-vcu128:
	$(call clone,buildroot,git://git.buildroot.net/buildroot,2021.11.2)
	mkdir -p $(CURDIR)/output/$@
	HOST_DIR=$(CURDIR)/install $(MAKE) O=$(CURDIR)/output/$@ BR2_EXTERNAL=$(CURDIR)/br2_external -C $(CURDIR)/buildroot occamy_vcu128_defconfig
	$(MAKE) -C $(CURDIR)/output/$@

clean:
	rm -rf .Xil occamy_vcu128 *.jou *.log *.str

.PHONY: program flash clean
