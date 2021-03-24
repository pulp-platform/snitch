# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.globl _start
.section .text.init;
_start:
    li   t0, 0x12345678
    li   t1, 0x100
    sw   t1, 0(t1)
    sw   t1, 4(t1)
    lw   t2, 0(t1)
    lw   t3, 4(t1)
    la   t1, magic
    lw   t4, 0(t1)
    la   t1, magic2
    lw   t5, 0(t1)
    la   t0, scratch_reg
    li   t1, 1
    sw   t1, 0(t0)
    wfi

.section .l1,"aw",@progbits
.global magic
.align 3
magic:
    .word 0x00000010
magic2:
    .word 0x00000042
