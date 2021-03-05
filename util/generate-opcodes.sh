#!/bin/bash
# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Generate the opcodes for the Snith system.
set -e
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

RISCV_OPCODES=$ROOT/sw/vendor/riscv-opcodes
OPCODES=(opcodes opcodes-dma opcodes-rep opcodes-ssr)

###########
# Banshee #
###########
INSTR_RS=$ROOT/sw/banshee/src/riscv.rs
cat > $INSTR_RS <<- EOM
// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

EOM

cd $RISCV_OPCODES && cat ${OPCODES[@]} | ./parse-opcodes -rust >> $INSTR_RS
rustfmt $INSTR_RS

#######
# RTL #
#######
OPCODES+=(opcodes-sflt opcodes-ipu)
INSTR_SV=$ROOT/hw/ip/snitch/src/riscv_instr.sv

cat > $INSTR_SV <<- EOM
// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

EOM
echo -e "// verilog_lint: waive-start parameter-name-style" >> $INSTR_SV
cd $RISCV_OPCODES && cat ${OPCODES[@]} | ./parse-opcodes -sverilog >> $INSTR_SV
echo -e "// verilog_lint: waive-stop parameter-name-style" >> $INSTR_SV
