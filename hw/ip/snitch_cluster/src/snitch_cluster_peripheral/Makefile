# Copyright 2021 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Noah Huetter <huettern@iis.ee.ethz.ch>

REGTOOL=../../../../../util/regtool.py
PYTHON3=$(shell which python)
CLANG_FORMAT=$(shell which clang-format-12.0.1)

SCHEMA=snitch_cluster_peripheral_reg.hjson

PKG=snitch_cluster_peripheral_reg_pkg.sv
TOP=snitch_cluster_peripheral_reg_top.sv
CDEF=../../../../../sw/snRuntime/include/snitch_cluster_peripheral.h

all: $(PKG) $(TOP) $(CDEF)

$(PKG): $(SCHEMA)
	$(PYTHON3) $(REGTOOL) -r -t $(dir $@) $<
$(TOP): $(SCHEMA)
	$(PYTHON3) $(REGTOOL) -r -t $(dir $@) $<

%.h: $(SCHEMA)
	$(PYTHON3) $(REGTOOL) -D -o $@ $<
	$(CLANG_FORMAT) -i $@
