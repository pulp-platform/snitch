# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

.global _start
_start:
    li    sp, 0x30001E00
    # write exception vector
    la    t0, exception
    csrw  mtvec, t0
    # That will park all 32-bit cores since it isn't a supported instruction.
    lwu   t0, main
    call  main
exception:
    wfi
    j     exception
entry_addr:
    .word exception

    .section .device_tree
    .globl device_tree
device_tree:
    .incbin "occamy.dtb"
