#!/bin/bash
# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set -e
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

INSTR_SV=$ROOT/hw/ip/snitch/src/riscv_instr.sv
HEADER="// Copyright 2020 ETH Zurich and University of Bologna.\n// Solderpad Hardware License, Version 0.51, see LICENSE for details.\n// SPDX-License-Identifier: SHL-0.51\n"

echo -e $HEADER > $INSTR_SV
echo -e "// verilog_lint: waive-start parameter-name-style" >> $INSTR_SV
cd $ROOT/sw/vendor/riscv-opcodes && \
    cat opcodes opcodes-rvc opcodes-rvc-pseudo opcodes-pseudo opcodes-sflt opcodes-dma opcodes-rep opcodes-ipu | ./parse-opcodes -sverilog >> $INSTR_SV
echo -e "// verilog_lint: waive-stop parameter-name-style" >> $INSTR_SV

