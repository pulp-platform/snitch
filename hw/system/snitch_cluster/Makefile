# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

VERILATOR       ?= verilator
VERILATOR_FLAGS += -Wno-BLKANDNBLK
VERILATOR_FLAGS += -Wno-LITENDIAN
VERILATOR_FLAGS += -Wno-CASEINCOMPLETE
VERILATOR_FLAGS += -Wno-CMPCONST
VERILATOR_FLAGS += -Wno-WIDTH
VERILATOR_FLAGS += -Wno-WIDTHCONCAT
VERILATOR_FLAGS += -Wno-UNSIGNED
VERILATOR_FLAGS += -Wno-UNOPTFLAT
VERILATOR_FLAGS += -Wno-fatal
VERILATOR_FLAGS += --unroll-count 1024

verilate:
	mkdir -p obj_dir
	bender script verilator -t rtl > obj_dir/files
	verilator src/snitch_cfg.sv -f obj_dir/files $(VERILATOR_FLAGS) --cc --top-module testharness

