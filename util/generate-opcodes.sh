#!/bin/bash
# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Generate the opcodes for the Snith system.
set -e
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

RISCV_OPCODES=$ROOT/sw/vendor/riscv-opcodes
OPCODES=(opcodes-pseudo opcodes-rv32i opcodes-rv64i opcodes-rv32m opcodes-rv64m opcodes-rv32a opcodes-rv64a opcodes-rv32h opcodes-rv64h opcodes-rv32f opcodes-rv64f opcodes-rv32d opcodes-rv64d opcodes-rv32q opcodes-rv64q opcodes-system opcodes-rvc opcodes-rv32c opcodes-rv64c opcodes-custom opcodes-rv32b_CUSTOM opcodes-dma_CUSTOM opcodes-frep_CUSTOM opcodes-ssr_CUSTOM opcodes-flt-occamy_CUSTOM opcodes-rvv-pseudo)

###########
# Banshee #
###########
INSTR_RS=$ROOT/sw/banshee/src/riscv.rs
cat > $INSTR_RS <<- EOM
// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

EOM

cd $RISCV_OPCODES && cat ${OPCODES[@]} | ./parse_opcodes -rust >> $INSTR_RS
rustfmt $INSTR_RS

#######
# RTL #
#######
OPCODES+=(opcodes-ipu_CUSTOM)
INSTR_SV=$ROOT/hw/ip/snitch/src/riscv_instr.sv

cat > $INSTR_SV <<- EOM
// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

EOM
echo -e "// verilog_lint: waive-start parameter-name-style" >> $INSTR_SV
cd $RISCV_OPCODES && cat ${OPCODES[@]} | ./parse_opcodes -sverilog >> $INSTR_SV
echo -e "// verilog_lint: waive-stop parameter-name-style" >> $INSTR_SV
