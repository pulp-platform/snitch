// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

int main() {
    uint32_t core_id = snrt_cluster_core_idx();
    uint32_t core_num = snrt_cluster_core_num();

    // One core at a time flushes its cache
    for (uint32_t i = 0; i < core_num; i++) {
        snrt_cluster_hw_barrier();
        if (i == core_id) {
            asm volatile("fence.i");
        }
    }
    // All cores flush their caches simultaneously
    for (uint32_t i = 0; i < core_num; i++) {
        snrt_cluster_hw_barrier();
        asm volatile("fence.i");
    }
    // Let us see if all cores arrive here
    snrt_cluster_hw_barrier();
    return 0;
}
