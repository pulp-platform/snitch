#!/bin/bash
# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Paul Scheffler <paulsc@iis.ee.ethz.ch>

# We treat accessing unwritten associative array (memory) locations as fatal
vsim tb_simple_ssr_streamer -t 1ps -coverage -voptargs="+acc +cover=sbecft"

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

