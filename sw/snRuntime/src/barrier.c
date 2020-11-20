// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
#include "snrt.h"

static void snrt_barrier_cluster() {
    asm volatile (" \
        lw t0, barrier_reg; \
        mv zero, t0; \
    " ::: "t0");
}

void snrt_barrier() {
    snrt_barrier_cluster();
}
