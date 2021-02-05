# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

.global _start
_start:
    csrr  a0, mhartid
    la    a1, device_tree
    lw    t0, entry_addr
    jalr  t0
no_payload:
    wfi
    j     no_payload
entry_addr:
    .word no_payload
device_tree:
