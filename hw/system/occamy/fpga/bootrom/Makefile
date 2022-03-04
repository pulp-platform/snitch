# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../../../..
ARIANE_SDK  ?= ${ROOT}/../ariane-sdk
INCLUDES = -I./ -I./src
SRCS_C = src/main.c src/uart.c
OBJS_C = $(SRCS_C:.c=.o)

CC = $(ARIANE_SDK)/install/bin/riscv64-unknown-elf-gcc
OBJDUMP = $(ARIANE_SDK)/install/bin/riscv64-unknown-elf-objdump
OBJCOPY = $(ARIANE_SDK)/install/bin/riscv64-unknown-elf-objcopy

GIT_SHA := $(shell git describe --match=NeVeRmAtCh --always --abbrev=10 --dirty)

.PHONY: all
all: bootrom-spl.coe

%.o: %.c
	$(CC) -DGIT_SHA=\"$(GIT_SHA)\" -Os -ggdb -march=rv64imafd -mabi=lp64d -Wall -mcmodel=medany -mexplicit-relocs -fno-builtin $(INCLUDES) -c $<  -o $@
	@echo "CC    <= $<"

%.dtb: %.dts
	dtc -I dts $< -O dtb -o $@

bootrom.elf bootrom.dump bootrom.bin: bootrom.S $(OBJS_C) bootrom.ld occamy.dtb
	$(CC) -mabi=lp64d -march=rv64imafd -static -nostartfiles $(INCLUDES) -Tbootrom.ld $< $(OBJS_C) -o bootrom.elf
	$(OBJDUMP) -d bootrom.elf > bootrom.dump
	$(OBJCOPY) --pad-to 0x1001000 -O binary bootrom.elf bootrom.bin

bootrom-spl.bin: bootrom.bin  $(ARIANE_SDK)/u-boot/spl/u-boot-spl.bin
	cat $^ > $@

%.coe: %.bin
	bin2coe -i $< -o $@ -w 32

clean:
	rm -rf *.bin *.coe *.dump src/*.o *.dtb
