# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

.global _start

_start:
    # Park non-64-bit cores: inspect MISA MSB
    csrr    t0, misa
    bltz    t0, _cva6_init

_snitch_init:
    la      t1, exception
    csrw    mtvec, t1
    csrr    a0, mhartid
    la      a1, boot_data
    lw      t2, entry_addr
    jalr    t2

_cva6_init:
    # Reset, ungate, deisolate each quadrant
    la      t0, __quad_count
    la      t1, __quad_int_base
    la      t2, __quad_stride
    li      t3, 1
1:  addi    t0, t0, -1
    # Assert reset
    sw      zero, 4(t1)
    # Ungate clock (sync reset)
    sw      t3, 0(t1)
    # Deassert reset
    sw      t3, 4(t1)
    # Deisolate quadrant
    sw      zero, 8(t1)
    # Move onto next quadrant
    add     t1, t1, t2

    fence

    bnez    t0, 1b

    # Set trap vector
    la      t2, exception
    csrw    mtvec, t2
    j       exception
exception:
    wfi
    j     exception
.align 3
device_tree:
    .incbin "test/occamy.dtb"

.pushsection .boot_section,"aw",@progbits;
entry_addr:
    .word exception
boot_data:
