// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

static volatile uint32_t *sink = (void *)0xF1230000;

int main() {
    uint32_t core_id = snrt_cluster_core_idx();
    uint32_t core_num = snrt_cluster_core_num();
    void *spm_start = (void *)snrt_cluster_memory().start;
    void *spm_end = (void *)snrt_cluster_memory().end;

    volatile uint32_t *x = spm_start + 4;
    if (core_id == 0) {
        *x = 0;
    }
    for (uint32_t i = 0; i < core_num; i++) {
        snrt_cluster_hw_barrier();
        if (i == core_id) {
            *sink = core_id;
            *x += 1;
        }
    }
    snrt_cluster_hw_barrier();
    return core_id == 0 ? core_num -= *x : 0;
}
