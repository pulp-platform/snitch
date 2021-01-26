// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

static void snrt_barrier_cluster() {
    asm volatile(
        " \
        lw t0, barrier_reg; \
        mv zero, t0; \
    " ::
            : "t0");
}

void snrt_barrier() { snrt_barrier_cluster(); }
