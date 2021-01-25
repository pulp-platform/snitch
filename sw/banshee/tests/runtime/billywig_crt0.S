# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.globl _start
.section .text.init;
_start:
    # Initialize global pointer
    .option push
    .option norelax
    1:auipc gp, %pcrel_hi(__global_pointer$)
      addi  gp, gp, %pcrel_lo(1b)
    .option pop
    /* reset vector */
    j reset_vector
reset_vector:
    la      sp, tcdm_end_address_reg # load stack top from peripheral register
    lw      sp, 0(sp)
    csrr    a0, mhartid # get hart id
    lw      t0, cluster_base_hart_id_reg
    sub     a0, a0, t0 # subtract cluster base hartid
    slli    t0, a0, 3 # misalign stacks in the TCDM
    sub     sp, sp, t0
    slli    t0, t0, 6 # set some stack-space aside for each hart
    sub     sp, sp, t0
    mv      tp, sp # place thread pointer on top of stack
    li      t0, 1
    slli    t0, t0, 9
    sub     tp, tp, t0 # subtract stack-size again
    la      t0, nr_cores_address_reg
    lw      a1, 0(t0) # load number of cores
    call    main # main(core_id, core_num)
    slli    a0, a0, 1
    ori     a0, a0, 1
    j       eoc
fail:
    li      t0, 0xFFFFFFFF
    xor     a0, a0, t0
    j       eoc
eoc:
    csrr    t0, mhartid
    bnez    t0, halt # only write exit code for core 0
    la      t0, scratch_reg
    sw      a0, 0(t0)
halt:
    wfi
    j       halt

.globl atomic_barrier
.section .l1,"aw",@progbits
atomic_barrier:
    .word 0
