// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

#define XSSR
#include "axpy.h"
#include "data.h"

int main() {
    uint32_t nerr = 0;
    double *local_x, *local_y, *local_z;

    // Allocate space in TCDM
    local_x = (double *)snrt_l1_next();
    local_y = local_x + l;
    local_z = local_y + l;

    // Copy data in TCDM
    if (snrt_is_dm_core()) {
        size_t size = l * sizeof(double);
        snrt_dma_start_1d(local_x, x, size);
        snrt_dma_start_1d(local_y, y, size);
    }

    snrt_cluster_hw_barrier();

    // Compute
    if (!snrt_is_dm_core()) {
        uint32_t start_cycle = mcycle();
        axpy(l, a, local_x, local_y, local_z);
        uint32_t end_cycle = mcycle();
    }

    snrt_cluster_hw_barrier();

    // Check computation is correct
    if (snrt_is_dm_core()) {
        for (int i = 0; i < l; i++) {
            if (local_z[i] != g[i]) nerr++;
        }
    }

    return nerr;
}
