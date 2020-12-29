# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Very basic test which parks all harts except 0 and then terminates the
# excution by calling into the HTIF.
.global _start
.section .text.init
_start:
    li t0, 1
    csrr a0, mhartid
    bnez a0, 1f
    la t1, .tohost
    sw t0, 0(t1)
1:
    j 1b

.pushsection .tohost,"aw",@progbits;
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;
