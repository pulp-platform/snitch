#!/bin/bash
# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Generate the opcodes for the Snith system.
set -e
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

RISCV_OPCODES=$ROOT/sw/vendor/riscv-opcodes
OPCODES=(opcodes opcodes-dma opcodes-rep opcodes-ssr opcodes-flt-occamy)

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
<<<<<<< HEAD
OPCODES=(opcodes opcodes-dma opcodes-rep opcodes-ssr opcodes-ipu opcodes-sflt) # TODO: change opcodes-sflt to opcodes-flt-occamy
=======
# OPCODES+=(opcodes-sflt opcodes-ipu)
OPCODES+=(opcodes-flt-occamy opcodes-ipu)
>>>>>>> 7fbc0191d3eacab4e0fb5b6f7f6fe76625214663
INSTR_SV=$ROOT/hw/ip/snitch/src/riscv_instr.sv

cat > $INSTR_SV <<- EOM
// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

EOM
echo -e "// verilog_lint: waive-start parameter-name-style" >> $INSTR_SV
cd $RISCV_OPCODES && cat ${OPCODES[@]} | ./parse-opcodes -sverilog >> $INSTR_SV
echo -e "// verilog_lint: waive-stop parameter-name-style" >> $INSTR_SV
