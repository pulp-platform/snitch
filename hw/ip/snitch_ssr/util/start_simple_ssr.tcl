#!/bin/bash
# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Paul Scheffler <paulsc@iis.ee.ethz.ch>

vsim tb_simple_ssr -t 1ps -voptargs=+acc

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*
