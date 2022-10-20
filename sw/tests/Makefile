# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

GCC    = riscv32-unknown-elf-gcc
CFLAGS = -T bare.ld -fno-builtin -nostdlib -static -march=rv64imafd

SRCS  = chaining.s
PROGS = $(patsubst %.s,%.out,$(SRCS))

%.out: %.s
	$(GCC) $(CFLAGS) $< -o $@

.PHONY: all
all: $(PROGS)

.PHONY: clean
clean:
	rm -f $(PROGS)
