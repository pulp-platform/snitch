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
    # De-isolate snitches
    la      t1, __soc_ctrl_isolate
    sw      zero, 0(t1)
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
