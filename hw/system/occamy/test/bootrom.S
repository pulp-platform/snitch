# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

.global _start
_start:
    csrr  a0, mhartid
    # write exception vector
    la    t0, exception
    csrw  mtvec, t0
    la    a1, device_tree
    # That will park all 32-bit cores since it isn't a supported instruction.
    lwu   t0, entry_addr
    jalr  t0
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
