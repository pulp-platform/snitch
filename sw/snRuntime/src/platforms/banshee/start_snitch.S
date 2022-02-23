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
    # shift core's hartid such that first core is 0
    lw        t1, cluster_base_hart_id_reg
    ; csrr      t2, mhartid
    sub       a0, a0, t1

    # Only first core triggers exit.
    # - a0: global core index
    # - t0: exit code
    bnez      a0, 1f
    slli      t0, t0, 1
    ori       t0, t0, 1
    la        t1, scratch_reg
    sw        t0, 0(t1)
1:  ret

.set scratch_reg, 0x40000020 # used as exit code location
.set cluster_base_hart_id_reg, 0x40000040
