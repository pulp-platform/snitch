# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.globl _start
.section .text.init;
_start:
    csrr    a0, mhartid
    li      a1, 0x40000040  # cluster_base_hartid
    lw      a1, 0(a1)
    slli    t0, a0, 4
    li      t1, 0x20000000
    add     t0, t0, t1
    sw      a0, 0(t0)
    sw      a1, 8(t0)
    la      t0, scratch_reg
    li      t1, 1
    sw      t1, 0(t0)
    wfi
