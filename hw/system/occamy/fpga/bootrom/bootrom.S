# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

.option push
.option norvc
.section .entry, "ax", %progbits
.global _start
_start:
    # control flow for cva6/snitch
    csrr  t0, mhartid
    bnez  t0, _snitch_bl_start
    j     _cva6_bl_start

.option pop

################################################################################
# CVA6 ENTRY
################################################################################

.globl _cva6_bl_start
_cva6_bl_start:
    # csrci 0x701, 1 # Disable D$

    # Setup exception vector
    la    t0, _cva6_exception
    csrw  mtvec, t0

    # setup stack halfway in HBM0
    li    sp, 0x84000000

    # jump to main
    call main

_cva6_exception:
    nop
    nop
    nop
    nop
    j     _cva6_exception


################################################################################
# Snitch ENTRY
################################################################################

#define MSTATUS_MIE (1<<3)
#define MIE_MSIE (1<<3)
#define MIE_MSIE (1<<3)
#define IRQ_M_CLUSTER 19
#define MIP_MCIP (1 << IRQ_M_CLUSTER)
#define MIE_MCIE (1 << IRQ_M_CLUSTER)

.option push
.option norvc

_snitch_bl_start:

_snitch_park:
    # Enable software interrupts
    la      t0, _snitch_resume
    csrw    mtvec, t0
    csrsi   mstatus, MSTATUS_MIE
    csrsi   mie, MIE_MSIE
    li      t0, MIE_MCIE
    csrs    mie, t0
    wfi

# Expected from snRuntime bootloader:
# - a0: mhartid
# - a1: device tree ptr
_snitch_resume:
    csrci   mstatus, MSTATUS_MIE
    csrci   mie, MIE_MSIE
    li      t0, MIE_MCIE
    csrc    mie, t0
    # Program memory might have changed, flush I$
    fence.i
    # Read boot address from scratch0
    # bootdata pointer from scratch1
    la      t0, __soc_ctrl_scratch0
    lw      t0, 0(t0)
    la      a1, __soc_ctrl_scratch1
    lw      a1, 0(a1)
    csrr    a0, mhartid
    jalr    ra, t0
    j       _snitch_park

.option pop

.section .rodata
.align 3
.globl device_tree
device_tree:
    .incbin "occamy.dtb"

#ifdef SPLBIN
.align 3
.section .spl
spl:
    .incbin SPLBIN
#endif
