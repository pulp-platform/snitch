#!/bin/bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Paul Scheffler <paulsc@iis.ee.ethz.ch>

set -e

[ ! -z "$VSIM" ] || VSIM=vsim

echo "vsim tb_axi_tlb -t 1ps  -voptargs="+acc"; log -r /*" > start.vsim.tcl

$VSIM -c -do 'exit -code [source start.vsim.tcl; run -a]'