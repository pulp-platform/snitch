# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.globl _start
.section .text.init;
_start:
    csrr    a0, mhartid
    slli    t0, a0, 3
    li      t1, 0x20000000
    add     t0, t0, t1
    sw      a0, 0(t0)
    wfi
