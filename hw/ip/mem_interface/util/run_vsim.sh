#!/bin/bash
# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Andreas Kurth  <akurth@iis.ee.ethz.ch>

set -e
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

[ ! -z "$VSIM" ] || VSIM=vsim

call_vsim() {
    echo "log -r /*; run -all" | $VSIM -c -coverage -voptargs='+acc +cover=sbecft' "$@" | tee vsim.log 2>&1
    grep "Errors: 0," vsim.log
}

call_vsim mem_wide_narrow_mux_tb