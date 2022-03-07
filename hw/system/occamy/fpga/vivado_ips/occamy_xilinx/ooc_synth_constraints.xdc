# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Noah Huetter <huettern@iis.ee.ethz.ch>

# Create a simple clock for better OOC synthesis results
create_clock -name occamy_ooc_synth_clk -period 20 [get_ports clk_i]
