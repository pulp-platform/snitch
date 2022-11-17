# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../../..
CVA6_SDK    ?= ${ROOT}/../cva6-sdk
DEBUG       ?= 0
VCU         ?= 01
FPGA_ID     := 091847100576A
HW_SERVER   := bordcomputer:3231

# Select VCU128-02
ifeq ($(VCU),02)
	FPGA_ID := 091847100638A
	HW_SERVER := bordcomputer:3232
endif

VIVADO ?= vivado
MKIMAGE ?= $(CURDIR)/br2_external/install/bin/mkimage
NPROC  ?= $(shell nproc)

# u-boot and OpenSBI wrapped in an mkimage wrapper
UBOOT_ITB = output/br-hrv-vcu128/images/u-boot.itb
# u-boot-wrapped image with kernel, rootfs and device tree blob. Name must match
# with the file fetched in u-boot command from TFTP server
FITIMG = output/br-hrv-vcu128/images/Image.itb
FITIMG_ITS = occamy_vcu128.its

DTB = bootrom/occamy.dtb

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
	${VIVADO} -mode batch -source occamy_vcu128_program.tcl -tclargs ${VCU}

flash: ${FILE}
	${VIVADO} -mode batch -source occamy_vcu128_flash.tcl -tclargs ${FPGA_ID} ${FILE} ${OFFSET}
	rm data.mcs

flashrun: ${UBOOT_ITB}
	${VIVADO} -mode batch -source occamy_vcu128_flashrun.tcl -tclargs ${HW_SERVER} ${FPGA_ID} flash.mcs 6000000 ${UBOOT_ITB}
	rm flash.mcs

flash: ${UBOOT_ITB}
	${VIVADO} -mode batch -source occamy_vcu128_flash.tcl -tclargs ${HW_SERVER} ${FPGA_ID} flash.mcs 6000000 ${UBOOT_ITB}
	rm flash.mcs
${UBOOT_ITB}:
	@echo "To generate u-boot.itb, run make 'br-hrv-vcu128'"

flash-u-boot:
	${MAKE} flash FILE=${CVA6_SDK}/u-boot/u-boot.itb OFFSET=0x6000000

flash-uimage:
	${MAKE} flash FILE=${CVA6_SDK}/uImage OFFSET=0x6100000

# `prepare-sdk` makes the host directory relocatable which is required 
# when cached with Memora
.PHONY: br-hrv-vcu128
br-hrv-vcu128:
	$(call clone,buildroot,git://git.buildroot.net/buildroot,2021.11.2)
	mkdir -p $(CURDIR)/output/$@
	HOST_DIR=$(CURDIR)/install $(MAKE) O=$(CURDIR)/output/$@ BR2_EXTERNAL=$(CURDIR)/br2_external -C $(CURDIR)/buildroot occamy_vcu128_defconfig
	$(MAKE) -C $(CURDIR)/output/$@
	$(MAKE) -C $(CURDIR)/output/$@ make prepare-sdk

.PHONY : linux-image
linux-image: $(FITIMG)
# Image sources must be in same directory as the ITS file
$(FITIMG): $(FITIMG_ITS) output/br-hrv-vcu128/images/Image $(DTB)
	cp $(DTB) $(@D)
	cp $(FITIMG_ITS) $(@D)
	gzip -c $(@D)/Image > $(@D)/Image.gz
	$(MKIMAGE) -f $(@D)/$(notdir $(FITIMG_ITS)) $(FITIMG)

.PHONY : upload-linux-image
upload-linux-image: $(FITIMG)
	scp $(FITIMG) vcu128-$(VCU)@bordcomputer.ee.ethz.ch:/srv/tftp/vcu128-$(VCU)

clean:
	rm -rf .Xil occamy_vcu128 *.jou *.log *.str

.PHONY: program flash clean
