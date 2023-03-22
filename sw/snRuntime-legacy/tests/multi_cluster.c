// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

#include "printf.h"

int main() {
    uint32_t global_core_id = snrt_global_core_idx();
    uint32_t global_core_num = snrt_global_core_num();
    uint32_t cluster_core_id = snrt_cluster_core_idx();
    uint32_t cluster_core_num = snrt_cluster_core_num();
    uint32_t cluster_id = snrt_cluster_idx();
    uint32_t cluster_num = snrt_cluster_num();

    uint32_t *cluster_sum = (uint32_t *)snrt_global_memory().start;
    uint32_t *core_cluster_sum = (uint32_t *)snrt_global_memory().start + 4;

    for (uint32_t i = 0; i < global_core_num; i++) {
        snrt_global_barrier();
        if (i == global_core_id) {
            *cluster_sum += (cluster_core_id == 0);
            core_cluster_sum[cluster_id] += 1;
        }
    }

    snrt_global_barrier();

    if (global_core_id == 0) {
        volatile uint32_t errors = 0;
        errors += (*cluster_sum != cluster_num);
        for (uint32_t i = 0; i < cluster_num; i++) {
            errors += (core_cluster_sum[i] != cluster_core_num);
        }
        return errors;
    } else {
        return 0;
    }
}
