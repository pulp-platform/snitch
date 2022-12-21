# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

#define CLUSTER0_CLINT_ADDR 0x10020000
#define CLUSTER_CLINT_SET_REG_OFFSET 0x00000030

.section .text._snitch_start

# Expected from bootloader:
# - a0: mhartid
# - a1: device tree ptr
_snitch_start:
    # Initialize registers (except a0 and a1)
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    #  x10 is a0
    #  x11 is a1
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
    # Information passed into the call:
    # - a0: mhartid
    # - a1: bootdata ptr
    call  _wakeup_cluster
    # Same information needed after the call!
    jal   _start

# Expected arguments:
# - a0: mhartid
# - a1: bootdata ptr
# Must not alter a0 and a1!
_wakeup_cluster:
    lw      a4,4(a1)                    # load core_count 
    lw      a5,8(a1)                    # load hartid_base
    sub     a2,a0,a5
    remu    a5,a2,a4                    # compute is_cluster_master
    bne     a5,zero,_wakeup_cluster_end # return if not master
    divu    a2,a2,a4                    # compute cluster_idx
    li      a5,1
    sll     a5,a5,a4
    li      a4,CLUSTER0_CLINT_ADDR      # load cluster0 CLINT addr
    addi    a4,a4,CLUSTER_CLINT_SET_REG_OFFSET # compute cluster0 CLINT set addr
    addi    a5,a5,-2                    # compute interrupt mask
    slli    a2,a2,18                    # cluster_idx*cluster_offset
    add     a2,a4,a2                    # cluster CLINT addr
    sw      a5,0(a2)                    # raise interrupts
_wakeup_cluster_end:
    ret