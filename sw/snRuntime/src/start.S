# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

.section .init
_start:
    .globl _start

#ifdef SNRT_INIT_INT_REGS
snrt.crt0.init_int_registers:
    # Clear integer registers
    mv t0, x0
    mv t1, x0
    mv t2, x0
    mv t3, x0
    mv t4, x0
    mv t5, x0
    mv t6, x0
    mv a0, x0
    mv a1, x0
    mv a2, x0
    mv a3, x0
    mv a4, x0
    mv a5, x0
    mv a6, x0
    mv a7, x0
    mv s0, x0
    mv s1, x0
    mv s2, x0
    mv s3, x0
    mv s4, x0
    mv s5, x0
    mv s6, x0
    mv s7, x0
    mv s8, x0
    mv s9, x0
    mv s10, x0
    mv s11, x0
#endif

#ifdef SNRT_INIT_FP_REGS
snrt.crt0.init_fp_registers:
    # Check if core has FP registers otherwise skip
    csrr    t0, misa
    andi    t0, t0, (1 << 3) | (1 << 5) # D/F - single/double precision float extension
    beqz    t0, 3f
    # Clear FP registers
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
#endif

#ifdef SNRT_INIT_GP
snrt.crt0.init_global_pointer:
    # Initialize global pointer
    .option push
    .option norelax
1:  auipc   gp, %pcrel_hi(__global_pointer$)
    addi    gp, gp, %pcrel_lo(1b)
    .option pop
#endif

#ifdef SNRT_INIT_CORE_INFO
snrt.crt0.init_core_info:
    # Initialize information needed by the following routines

    # Calculate cluster idx
    csrr a0, mhartid
    li   t0, SNRT_BASE_HARTID
    sub  a0, a0, t0
    li   a1, SNRT_CLUSTER_CORE_NUM
    div  t0, a0, a1

    # Calculate cluster-local core ID
    remu a0, a0, a1

    # Calculate cluster's TCDM start address
    li   a2, SNRT_TCDM_START_ADDR
    li   t1, SNRT_CLUSTER_OFFSET
    mul  t0, t1, t0
    add  a2, a2, t0

    # Calculate cluster's TCDM end address
    li   t0, SNRT_TCDM_SIZE
    add  a2, a2, t0
#endif

#ifdef SNRT_INIT_CLS
snrt.crt0.init_cls:
    # Reserve space in TCDM for cluster-local storage
    la        t0, __cdata_end
    la        t1, __cdata_start
    sub       t0, t0, t1
    sub       a2, a2, t0
    la        t0, __cbss_end
    la        t1, __cbss_start
    sub       t0, t0, t1
    sub       a2, a2, t0
#endif

#ifdef SNRT_INIT_STACK
snrt.crt0.init_stack:
    # TODO colluca: do we need this?
    # Set 8 bytes aside for the main return value and clear that to zero.
    addi      a2, a2, -8
    sw        zero, 0(a2)

    # Compute the relative start address of the stack for each hart.
    # The stack for hart N starts at the end of the stack of hart N-1.
    sll       t0, a0, SNRT_LOG2_STACK_SIZE
    
    # Initialize the stack pointer to the start of the stack
    sub       sp, a2, t0

    # Calculate the end of the stack, could be used by later routines
    # to calculate remaining TCDM space
    sll       t1, a1, t2    
    sub       a2, a2, t1

    # Misalign stacks in the TCDM to reduce banking conflicts
    slli      t0, a0, 3  # this hart
    slli      t1, a1, 3  # all harts
    sub       sp, sp, t0
    sub       a2, a2, t1
#endif

#ifdef SNRT_INIT_TLS
snrt.crt0.init_tls:
    # Reserve space for thread-local storage at the top of the stack
    la        t0, __tdata_end
    la        t1, __tdata_start
    sub       t0, t0, t1
    sub       sp, sp, t0
    la        t0, __tbss_end
    la        t1, __tbss_start
    sub       t0, t0, t1
    sub       sp, sp, t0
    andi      sp, sp, ~0x7 # align to 8B
    # Set tp to the base of the tls
    mv        tp, sp
    # TODO colluca: why again?
    andi      sp, sp, ~0x7 # align stack to 8B
#endif

#ifdef SNRT_INIT_INTERRUPT
snrt.crt0.init_interrupt:
    # Prepare interrupts
    la t0, __snrt_crt0_interrupt_handler
    csrw   mtvec, t0
#endif

snrt.crt0.main:
    call snrt_main

#ifdef SNRT_CRT0_PARK
snrt.crt0.end:
1:
    wfi
    j       1b
#endif

#ifdef SNRT_INIT_INTERRUPT
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
#endif

# HTIF sections
.pushsection .htif,"aw",@progbits;
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;
