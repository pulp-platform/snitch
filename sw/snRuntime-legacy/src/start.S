# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# This file defines the `_start` symbol and initializes the global pointer. This
# is common among all bare runtimes.


# Expected from bootloader:
# - a0: mhartid
# - a1: device tree ptr
.section .init
_start:
    .globl _start

    # Initialize global pointer
snrt.crt0.init_global_pointer:
    .option push
    .option norelax
1:  auipc     gp, %pcrel_hi(__global_pointer$)
    addi      gp, gp, %pcrel_lo(1b)
    .option pop

snrt.crt0.init_core_info:
    # Information passed into the call:
    # - a0: mhartid (from bootloader)
    # - a1: device tree ptr (from bootloader)
    call      _snrt_init_core_info
    # Information needed after the call:
    # - a0: cluster-local core id
    # - a1: cluster-local core count
    # - a2: TCDM start ptr
    # - a3: TCDM end ptr
    # - a4: device tree ptr

    # Clear the bss segment.
snrt.crt0.init_bss:
    # Takes device tree ptr as argument and returns the hart base ID
    mv        s0, a0 # store a0 in s0 since we dont have a stack yet
    mv        a0, a4
    call      _snrt_get_base_hartid
    mv        t0, a0
    mv        a0, s0
    # only core 0. t0: return value base hartid
    csrr      t1, mhartid
    sub       t0, t1, t0
    bnez      t0, 2f
    la        t0, _edata
    la        t1, _end
    bge       t0, t1, 2f
1:  sw        zero, 0(t0)
    addi      t0, t0, 4
    blt       t0, t1, 1b
2:

snrt.crt0.init_registers:
    # Clear FP registers
    csrr    t0, misa
    andi    t0, t0, (1 << 3) | (1 << 5) # D/F - single/double precision float extension
    beqz    t0, 3f
    fcvt.d.w f0, zero
    fcvt.d.w f1, zero
    fcvt.d.w f2, zero
    fcvt.d.w f3, zero
    fcvt.d.w f4, zero
    fcvt.d.w f5, zero
    fcvt.d.w f6, zero
    fcvt.d.w f7, zero
    fcvt.d.w f8, zero
    fcvt.d.w f9, zero
    fcvt.d.w f10, zero
    fcvt.d.w f11, zero
    fcvt.d.w f12, zero
    fcvt.d.w f13, zero
    fcvt.d.w f14, zero
    fcvt.d.w f15, zero
    fcvt.d.w f16, zero
    fcvt.d.w f17, zero
    fcvt.d.w f18, zero
    fcvt.d.w f19, zero
    fcvt.d.w f20, zero
    fcvt.d.w f21, zero
    fcvt.d.w f22, zero
    fcvt.d.w f23, zero
    fcvt.d.w f24, zero
    fcvt.d.w f25, zero
    fcvt.d.w f26, zero
    fcvt.d.w f27, zero
    fcvt.d.w f28, zero
    fcvt.d.w f29, zero
    fcvt.d.w f30, zero
    fcvt.d.w f31, zero
3:

    # Read hartid and number of cores in the cluster.
snrt.crt0.init_stack:

    # Set 8 bytes aside for the main return value and clear that to zero.
    addi      a3, a3, -8
    sw        zero, 0(a3)

    # Set space aside for the root team structure.
    lw        t0, _snrt_team_size
    sub       a3, a3, t0
    mv        a5, a3

    # Compute the stack top for this hart, and the cluster-wide stack bottom.
    lw        t2, snrt_stack_size  # load stack size (overridable by binary)

    sll       t0, a0, t2  # this hart
    sll       t1, a1, t2  # all harts
    sub       sp, a3, t0
    sub       a3, a3, t1

    # Misalign stacks in the TCDM to reduce banking conflicts
    slli      t0, a0, 3  # this hart
    slli      t1, a1, 3  # all harts
    sub       sp, sp, t0
    sub       a3, a3, t1

    # Allocate thread-local storage at the top of the stack and set tp
    # to the base of the tls
snrt.crt0.init_tls:
    la        t0, __tdata_start
    la        t1, __tdata_end
    la        t2, __tbss_start
    la        t3, __tbss_end
    add       sp, sp, t0   # subtract sp to make room for TLS and align
    sub       sp, sp, t1
    add       sp, sp, t2
    sub       sp, sp, t3
    andi      sp, sp, ~0x7
    mv        tp, sp       # palce tp at start of TLS
    andi      sp, sp, ~0x7 # align stack to 8B

    # Copy __tdata_start to __tdata_end.
    mv        t4, tp
    bge       t0, t1, 2f
1:  lw        t5, 0(t0)
    sw        t5, 0(t4)
    addi      t0, t0, 4
    addi      t4, t4, 4
    blt       t0, t1, 1b
2:

    # Clear from _tdata_end to _tbss_end.
    la        t0, __tbss_start
    la        t1, __tbss_end
    bge       t0, t1, 2f
1:  sw        zero, 0(t4)
    addi      t0, t0, 4
    addi      t4, t4, 4
    blt       t0, t2, 1b
2:

    # Initialize the root team.
snrt.crt0.init_team:
    addi      sp, sp, -20
    sw        a0, 0(sp)
    sw        a1, 4(sp)
    sw        a2, 8(sp)
    sw        a3, 12(sp)
    sw        a4, 16(sp)
    call      _snrt_init_team
    lw        a0, 0(sp)
    lw        a1, 4(sp)
    lw        a2, 8(sp)
    lw        a3, 12(sp)
    lw        a4, 16(sp)
    addi      sp, sp, 20

    # Prepare interrupts
snrt.crt0.init_interrupt:
    la t0, __snrt_crt0_interrupt_handler
    csrw   mtvec, t0

    # Synchronize cores.
snrt.crt0.pre_barrier:
    call      _snrt_cluster_barrier

    # Execute the main function.
snrt.crt0.main:
    call      main  # main(int core_id, int core_num, void *spm_start, void *spm_end)
    mv        s0, a0 # store return value in s0
    # lw        s0, tcdm_end_address_reg  # add return value to special slot
    # addi      s0, s0, -8
    # amoadd.w  zero, a0, (s0)

    # Synchronize cores.
snrt.crt0.post_barrier:
    call      _snrt_cluster_barrier

    # Write execution result to EOC register.
snrt.crt0.end:
    mv        a0, s0 # recover return value of main function in s0
    call      _snrt_exit
1:
    wfi
    j       1b

__snrt_crt0_interrupt_handler:
    .align 4
    .globl __snrt_crt0_interrupt_handler
    # store integer context: 17 registers, align stack to 16
    addi    sp, sp, -80
    sw  ra, 64(sp)
    sw  t0, 60(sp)
    sw  t1, 56(sp)
    sw  t2, 52(sp)
    sw  s0, 48(sp)
    sw  a0, 44(sp)
    sw  a1, 40(sp)
    sw  a2, 36(sp)
    sw  a3, 32(sp)
    sw  a4, 28(sp)
    sw  a5, 24(sp)
    sw  a6, 20(sp)
    sw  a7, 16(sp)
    sw  t3, 12(sp)
    sw  t4,  8(sp)
    sw  t5,  4(sp)
    sw  t6,  0(sp)
    # store double floating point context: 32*8 bytes
    csrr    t0, misa
    andi    t0, t0, (1 << 3) # 3: D - single precision float extension
    beqz    t0, 1f
    addi    sp, sp, -256
    fsd     f0, 248(sp)
    fsd     f1, 240(sp)
    fsd     f2, 232(sp)
    fsd     f3, 224(sp)
    fsd     f4, 216(sp)
    fsd     f5, 208(sp)
    fsd     f6, 200(sp)
    fsd     f7, 192(sp)
    fsd     f8, 184(sp)
    fsd     f9, 176(sp)
    fsd     f10, 168(sp)
    fsd     f11, 160(sp)
    fsd     f12, 152(sp)
    fsd     f13, 144(sp)
    fsd     f14, 136(sp)
    fsd     f15, 128(sp)
    fsd     f16, 120(sp)
    fsd     f17, 112(sp)
    fsd     f18, 104(sp)
    fsd     f19, 96(sp)
    fsd     f20, 88(sp)
    fsd     f21, 80(sp)
    fsd     f22, 72(sp)
    fsd     f23, 64(sp)
    fsd     f24, 56(sp)
    fsd     f25, 48(sp)
    fsd     f26, 40(sp)
    fsd     f27, 32(sp)
    fsd     f28, 24(sp)
    fsd     f29, 16(sp)
    fsd     f30, 8(sp)
    fsd     f31, 0(sp)
    # state is stored, can now handle the interrupt
1:  
    call    __snrt_isr
    # restore fp context
    csrr    t0, misa
    andi    t0, t0, (1 << 3) # 3: D - single precision float extension
    beqz    t0, 1f
    fld     f0, 248(sp)
    fld     f1, 240(sp)
    fld     f2, 232(sp)
    fld     f3, 224(sp)
    fld     f4, 216(sp)
    fld     f5, 208(sp)
    fld     f6, 200(sp)
    fld     f7, 192(sp)
    fld     f8, 184(sp)
    fld     f9, 176(sp)
    fld     f10, 168(sp)
    fld     f11, 160(sp)
    fld     f12, 152(sp)
    fld     f13, 144(sp)
    fld     f14, 136(sp)
    fld     f15, 128(sp)
    fld     f16, 120(sp)
    fld     f17, 112(sp)
    fld     f18, 104(sp)
    fld     f19, 96(sp)
    fld     f20, 88(sp)
    fld     f21, 80(sp)
    fld     f22, 72(sp)
    fld     f23, 64(sp)
    fld     f24, 56(sp)
    fld     f25, 48(sp)
    fld     f26, 40(sp)
    fld     f27, 32(sp)
    fld     f28, 24(sp)
    fld     f29, 16(sp)
    fld     f30, 8(sp)
    fld     f31, 0(sp)
    addi    sp, sp, 256
    # restore integer context
1:
    lw  t6,  0(sp)
    lw  t5,  4(sp)
    lw  t4,  8(sp)
    lw  t3, 12(sp)
    lw  a7, 16(sp)
    lw  a6, 20(sp)
    lw  a5, 24(sp)
    lw  a4, 28(sp)
    lw  a3, 32(sp)
    lw  a2, 36(sp)
    lw  a1, 40(sp)
    lw  a0, 44(sp)
    lw  s0, 48(sp)
    lw  t2, 52(sp)
    lw  t1, 56(sp)
    lw  t0, 60(sp)
    lw  ra, 64(sp)
    addi    sp, sp, 80
    # return from interrupt context
    mret
