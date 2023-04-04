# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../../../..

include $(ROOT)/util/Makefrag

CVA6_SDK  ?= $(ROOT)/../cva6-sdk
UBOOT_SPL_BIN ?= $(CVA6_SDK)/u-boot/spl/u-boot-spl.bin

# Define UBOOT_SPL_BIN in command line with the path to u-boot-spl.bin

CROSS_COMPILE = riscv64-unknown-elf-
INCLUDES = -I./ -I./src
SRCS_C = src/main.c src/uart.c
OBJS_C = $(SRCS_C:.c=.o)

CC = $(CROSS_COMPILE)gcc
OBJDUMP = $(CROSS_COMPILE)objdump
OBJCOPY = $(CROSS_COMPILE)objcopy

CFLAGS 	= -Os -g -Werror -ffreestanding -fno-strict-aliasing
CFLAGS += -static -nostartfiles -nostartfiles
CFLAGS += -fno-omit-frame-pointer -fno-optimize-sibling-calls -fno-stack-protector
CFLAGS += -mno-save-restore -mstrict-align
CFLAGS += -mabi=lp64d -march=rv64imafd
CFLAGS += -mcmodel=medany

GIT_SHA := $(shell git describe --match=NeVeRmAtCh --always --abbrev=10 --dirty)

.PHONY: all
all: bootrom-spl.coe bootrom.tcl bootrom-spl.tcl

%.o: %.c
	$(CC) $(CFLAGS) -DGIT_SHA=\"$(GIT_SHA)\"  $(INCLUDES) -c $<  -o $@
	@echo "CC    <= $<"

%.dtb: %.dts
	dtc -I dts $< -O dtb -o $@

bootrom.elf bootrom.dump bootrom.bin: bootrom.S $(OBJS_C) bootrom.ld occamy.dtb
	$(CC) $(CFLAGS) $(INCLUDES) -Tbootrom.ld $< $(OBJS_C) -o bootrom.elf
	$(OBJDUMP) -d bootrom.elf > bootrom.dump
	$(OBJCOPY) -O binary bootrom.elf bootrom.bin

check-uboot:
	@[ "${UBOOT_SPL_BIN}" ] || ( echo "UBOOT_SPL_BIN is not set"; exit 1 )
bootrom-spl.bin: check-uboot

bootrom-spl.bin: bootrom.S $(OBJS_C) bootrom.ld occamy.dtb
	$(CC) $(CFLAGS) $(INCLUDES) -Tbootrom.ld -DSPLBIN=\"$(UBOOT_SPL_BIN)\" $< $(OBJS_C) -o bootrom-spl.elf
	$(OBJDUMP) -d bootrom-spl.elf > bootrom-spl.dump
	$(OBJCOPY) -O binary bootrom-spl.elf bootrom-spl.bin

%.coe: %.bin
	bin2coe -i $< -o $@ -w 32

clean:
	rm -rf *.bin *.coe *.dump src/*.o *.dtb *.elf *.tcl

# Generate a TCL script to configure the bootrom on the FPGA
%.tcl:  %.bin
	@echo "TCL   <= $<"
	@$(call BINRAY_SIZE_CHECK,$<,1000000)
	@$(BIN2JTAG) -c32 -b 0 -d hw_axi_1 $< > $@
