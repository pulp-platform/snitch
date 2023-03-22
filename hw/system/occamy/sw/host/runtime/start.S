// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

.section .text.startup

.globl _start
_start:
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0
    la sp, __stack_pointer$
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop
    call initialize_bss
    call enable_fpu
    call main

# Expecting:
# - a0: exit code
_exit:
    # Return exit code to host to terminate simulation
    slli      a0, a0, 1
    ori       a0, a0, 1
    la        t0, tohost
    sw        a0, 0(t0) # (exit code << 1) | 1
    fence
    wfi

# HTIF sections
.pushsection .htif,"aw",@progbits;
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;

.section .devicebin,"a",@progbits
.globl snitch_main
.align 4
snitch_main:
#ifdef DEVICEBIN
    .incbin DEVICEBIN
#endif
