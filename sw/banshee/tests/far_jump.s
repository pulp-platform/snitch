# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.globl _start
.section .text.init;
_start:
    li      a0, 1
    li      t0, 0
    li      t1, 1
1:  bne     t0, t1, .+2468
    j       end
    # Fill in some padding bytes
    .fill   1b+2468-., 1, 0
fix:
    li      a0, 0
end:
    slli    a0, a0, 1
    ori     a0, a0, 1
    la      t0, scratch_reg
    sw      a0, 0(t0)
    wfi
