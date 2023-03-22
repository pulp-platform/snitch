// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

void axpy(uint32_t l, double a, double* x, double* y, double* z) {
    int core_idx = snrt_cluster_core_idx();
    int frac = l / snrt_cluster_core_num();
    int offset = core_idx * frac;

    for (int i = 0; i < frac; i++) {
        z[offset] = a * x[offset] + y[offset];
        offset++;
    }
    snrt_fpu_fence();
}
