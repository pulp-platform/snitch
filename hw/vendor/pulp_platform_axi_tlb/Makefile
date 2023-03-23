# Copyright 2018-2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

all:

clean:
	rm -rf .bender
	rm -f bender Bender.lock

bender:
	curl --proto '=https' --tlsv1.2 -sSf https://pulp-platform.github.io/bender/init | bash -s -- 0.25.3
	touch bender

# Generate TLB RTL

BENDER = ./bender
AXI_TLB_ROOT = .
axi_tlb.mk: bender # Bender is needed by make fragment
include axi_tlb.mk

all: axi_tlb

# Checks

CHECK_CLEAN = git status && test -z "$$(git status --porcelain)"

check_generated:
	$(MAKE) -B axi_tlb
	$(CHECK_CLEAN)

check: check_generated

# Simulation using QuestaSim

clean: clean_vsim

clean_vsim:
	rm -rf test/work
	rm -f transcript *.wlf wlf*
	rm -f test/*.tcl

vsim: clean_vsim bender
	cd test && ./compile.vsim.sh
	cd test && ./run.vsim.sh
