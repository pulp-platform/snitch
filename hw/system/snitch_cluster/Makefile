# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

VERILATOR       ?= verilator
VERILATOR_ROOT  ?= $$(dirname $$(which $(VERILATOR)))/../share/verilator
# Try to derive a meaningful path to the RISC-V installation.
SPIKE           ?= spike
RISCV			?= $$(dirname $$(which $(SPIKE)))/..
VERILATOR_FLAGS += -Wno-BLKANDNBLK
VERILATOR_FLAGS += -Wno-LITENDIAN
VERILATOR_FLAGS += -Wno-CASEINCOMPLETE
VERILATOR_FLAGS += -Wno-CMPCONST
VERILATOR_FLAGS += -Wno-WIDTH
VERILATOR_FLAGS += -Wno-WIDTHCONCAT
VERILATOR_FLAGS += -Wno-UNSIGNED
VERILATOR_FLAGS += -Wno-UNOPTFLAT
VERILATOR_FLAGS += -Wno-fatal
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --unroll-count 1024

CFLAGS ?= -std=c++14 -I obj_dir -I $(VERILATOR_ROOT)/include -I $(VERILATOR_ROOT)/include/vltstd -I $(RISCV)/include

build:
	$(CXX) $(CFLAGS) -c test/tb_lib.cc -o obj_dir/tb_lib.o
	$(CXX) $(CFLAGS) -c $(VERILATOR_ROOT)/include/verilated.cpp -o obj_dir/verilated.o
	$(CXX) $(CFLAGS) -c $(VERILATOR_ROOT)/include/verilated_dpi.cpp -o obj_dir/verilated_dpi.o
	$(CXX) $(CFLAGS) -c $(VERILATOR_ROOT)/include/verilated_vcd_c.cpp -o obj_dir/verilated_vcd_c.o
	mkdir -p bin
	$(LD) -o obj_dir/snitch_cluster.o -r \
		obj_dir/tb_lib.o \
		obj_dir/verilated.o \
		obj_dir/verilated_dpi.o \
		obj_dir/verilated_vcd_c.o \
		obj_dir/Vtestharness__ALL.a \
		-lfesvr \
		-L obj_dir \
		-L $(RISCV)/lib
	$(AR) rcs bin/libsnitch_cluster.a obj_dir/snitch_cluster.o
	$(CXX) $(CFLAGS) test/tb_bin.cc -L bin -lsnitch_cluster -o bin/snitch_cluster

verilate:
	mkdir -p obj_dir
	bender script verilator -t rtl > obj_dir/files
	verilator src/snitch_cfg.sv -f obj_dir/files $(VERILATOR_FLAGS) --cc --build --top-module testharness

traces: $(shell ls trace_hart_*.dasm | sed 's/\.dasm/\.txt/')

trace_hart_%.txt: trace_hart_%.dasm
	spike-dasm < $< > $@

test/sw/alive: test/sw/alive.S test/sw/link.ld
	riscv64-unknown-elf-gcc -mabi=ilp32d -march=rv32imafd -static -nostartfiles $< -T test/sw/link.ld -o $@

clean:
	rm -rf obj_dir Bender.lock .bender/
