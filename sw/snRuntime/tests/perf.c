// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "printf.h"
#include "snrt.h"

int main() {
    if (snrt_cluster_core_idx() == 0) {
        uint32_t counter;

        printf("Measuring cycles\n");
        counter = snrt_get_perf_counter(SNRT_PERF_CNT0);
        printf("Start: %d cycles\n", counter);

        // Start performance counter
        snrt_start_perf_counter(SNRT_PERF_CNT0, SNRT_PERF_CNT_CYCLES, 0);

        // Wait for some cycles
        for (int i = 0; i < 100; i++) {
            asm volatile("nop");
        }

        // Stop performance counter
        snrt_stop_perf_counter(SNRT_PERF_CNT0);

        // Get performance counters
        counter = snrt_get_perf_counter(SNRT_PERF_CNT0);
        printf("End: %d cycles\n", counter);

        // Reset counter
        snrt_reset_perf_counter(SNRT_PERF_CNT0);
        counter = snrt_get_perf_counter(SNRT_PERF_CNT0);
    }

    uint32_t tcdm_accesses, tcdm_congestion;

    if (snrt_cluster_core_idx() == 0) {
        printf("Measuring TCDM congestion\n");
        tcdm_accesses = snrt_get_perf_counter(SNRT_PERF_CNT0);
        tcdm_congestion = snrt_get_perf_counter(SNRT_PERF_CNT1);
        printf("Start: %d/%d Congestion/Accesses\n", tcdm_congestion,
               tcdm_accesses);

        // Start performance counters
        snrt_start_perf_counter(SNRT_PERF_CNT0, SNRT_PERF_CNT_TCDM_ACCESSED, 0);
        snrt_start_perf_counter(SNRT_PERF_CNT1, SNRT_PERF_CNT_TCDM_CONGESTED,
                                0);
    }

    snrt_cluster_hw_barrier();

    // Keep TCDM busy
    volatile uint32_t *ptr = (void *)snrt_cluster_memory().start;
    for (uint32_t i = 0; i < 100; i++) {
        *ptr = 0xdeadbeef;
    }

    if (snrt_cluster_core_idx() == 0) {
        // Stop performance counter
        snrt_stop_perf_counter(SNRT_PERF_CNT0);
        snrt_stop_perf_counter(SNRT_PERF_CNT1);

        // Get performance counters
        tcdm_accesses = snrt_get_perf_counter(SNRT_PERF_CNT0);
        tcdm_congestion = snrt_get_perf_counter(SNRT_PERF_CNT1);
        printf("End: %d/%d Congestion/Accesses\n", tcdm_congestion,
               tcdm_accesses);
    }

    return 0;
}
