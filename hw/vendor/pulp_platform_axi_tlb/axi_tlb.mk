# Copyright 2018-2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

# Import this GNU Make fragment in your project's makefile to regenerate and
# reconfigure these IPs. You can modify the original RTL, configuration, and
# templates from your project without entering this dependency repo by adding
# build targets for them. To build the IPs, `make axi_tlb`.

# You may need to adapt these environment variables to your configuration.
BENDER 	?= bender
PYTHON3	?= /usr/bin/env python3
REGTOOL	?= $(shell $(BENDER) path register_interface)/vendor/lowrisc_opentitan/util/regtool.py

AXI_TLB_ROOT       ?= $(shell $(BENDER) path axi_tlb)
AXI_TLB_NAME       ?= tlb
AXI_TLB_NUMENTRIES ?= 8
AXI_TLB_ADDRWIDTH  ?= 64

define axi_tlb_render
	$(PYTHON3) -c "from mako.template import Template;\
	print(Template(filename='$<').render(\
	num_entries = $(AXI_TLB_NUMENTRIES),\
	addr_width  = $(AXI_TLB_ADDRWIDTH),\
	tlb_name    = '$(AXI_TLB_NAME)',\
	))" >$@
endef

$(AXI_TLB_ROOT)/data/axi_${AXI_TLB_NAME}_reg.hjson: $(AXI_TLB_ROOT)/data/axi_tlb_reg.hjson.tpl
	$(call axi_tlb_render)

$(AXI_TLB_ROOT)/src/axi_${AXI_TLB_NAME}.sv: $(AXI_TLB_ROOT)/src/axi_tlb.sv.tpl
	$(call axi_tlb_render)

_axi_tlb: $(AXI_TLB_ROOT)/data/axi_${AXI_TLB_NAME}_reg.hjson $(AXI_TLB_ROOT)/src/axi_${AXI_TLB_NAME}.sv $(REGTOOL)
	$(REGTOOL) $< -r --outdir $(AXI_TLB_ROOT)/src/

axi_tlb:
	@echo "[PULP] Generate AXI_TLB (NAME=$(AXI_TLB_NAME), NUMENTRIES=$(AXI_TLB_NUMENTRIES), ADDRWIDTH=$(AXI_TLB_ADDRWIDTH))"
	@$(MAKE) -B _axi_tlb
