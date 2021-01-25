# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.globl _start
.section .text.init;
_start:
    ## Initialize global pointer
    .option push
    .option norelax
    1:auipc gp, %pcrel_hi(__global_pointer$)
      addi  gp, gp, %pcrel_lo(1b)
    .option pop
    /* reset vector */
    j reset_vector
.section .text;
reset_vector:
    li      x1, 0
    li      x4, 0
    li      x5, 0
    li      x6, 0
    li      x7, 0
    li      x8, 0
    li      x9, 0
    li      x10, 0
    li      x11, 0
    li      x12, 0
    li      x13, 0
    li      x14, 0
    li      x15, 0
    li      x16, 0
    li      x17, 0
    li      x18, 0
    li      x19, 0
    li      x20, 0
    li      x10, 0
    li      x21, 0
    li      x22, 0
    li      x23, 0
    li      x24, 0
    li      x25, 0
    li      x26, 0
    li      x27, 0
    li      x28, 0
    li      x29, 0
    li      x30, 0
    li      x31, 0
    ## get system info
    la      sp, tcdm_end_address_reg # load stack top from peripheral register
    lw      sp, 0(sp)
    ## get hart id and number of cores in the cluster
    csrr    a0, mhartid
    la      a1, nr_cores_address_reg # get the number of cores per cluster
    lw      a1, 0(a1)
    # check if the core has the F-extension
    csrr    t0, misa
    andi    t0, t0, (1 << 5)
    beqz    t0, 1f
    ## clear FP registers
    fmv.s.x f0, x0
    fmv.s.x f1, x0
    fmv.s.x f4, x0
    fmv.s.x f5, x0
    fmv.s.x f6, x0
    fmv.s.x f7, x0
    fmv.s.x f8, x0
    fmv.s.x f9, x0
    fmv.s.x f10, x0
    fmv.s.x f11, x0
    fmv.s.x f12, x0
    fmv.s.x f13, x0
    fmv.s.x f14, x0
    fmv.s.x f15, x0
    fmv.s.x f16, x0
    fmv.s.x f17, x0
    fmv.s.x f18, x0
    fmv.s.x f19, x0
    fmv.s.x f20, x0
    fmv.s.x f10, x0
    fmv.s.x f21, x0
    fmv.s.x f22, x0
    fmv.s.x f23, x0
    fmv.s.x f24, x0
    fmv.s.x f25, x0
    fmv.s.x f26, x0
    fmv.s.x f27, x0
    fmv.s.x f28, x0
    fmv.s.x f29, x0
    fmv.s.x f30, x0
    fmv.s.x f31, x0
1:  la      t0, cluser_base_hart_id_reg
    lw      a2, 0(t0)
    sub     t0, a0, a2
    slli    t0, t0, 12 # set some stack-space aside for each hart
    sub     sp, sp, t0
run:
    call    main
eoc:
    la t0, eoc_address
    sw a0, 0(t0)
    jal x0, eoc
fail:
    la t0, eoc_address
    sw a0, 0(t0)
    jal x0, eoc

.section ".eoc_address","aw",@progbits
.align 6
.globl eoc_address
eoc_address: .dword 0

.section .text
.section .data
