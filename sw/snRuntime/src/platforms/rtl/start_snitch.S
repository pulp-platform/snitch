# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

#include "../shared/start_snitch.S"

# Function to terminate execution.
#
# Expecting:
# - a0: exit code
# - a1: device tree ptr
_snrt_exit:
    .globl _snrt_exit
    # Determine global core index.
    addi      sp, sp, -8
    sw        a0, 0(sp)
    sw        ra, 4(sp)
    call      snrt_global_core_idx
    # reload exit code into t0
    lw        t0, 0(sp)
    lw        ra, 4(sp)
    addi      sp, sp, 8

    # Only first core triggers exit.
    # - a0: global core index
    # - t0: exit code
    bnez      a0, 1f
    slli      t0, t0, 1
    ori       t0, t0, 1
    la        t1, tohost
    sw        t0, 0(t1)
1:  ret

# HTIF sections
.pushsection .htif,"aw",@progbits;
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;
