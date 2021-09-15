// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "perf_cnt.h"

#include "printf.h"
#include "snrt.h"

int main() {
    uint32_t core_idx = snrt_cluster_core_idx();

    if (core_idx == 0) {
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
    }

    snrt_cluster_hw_barrier();

    if (snrt_is_dm_core()) {
        uint32_t read_bytes, write_bytes;

        printf("Measuring DMA perf\n");
        read_bytes = snrt_get_perf_counter(SNRT_PERF_CNT0);
        write_bytes = snrt_get_perf_counter(SNRT_PERF_CNT1);
        printf("Start: %d/%d bytes read, written\n", read_bytes, write_bytes);

        // Start performance counter
        snrt_start_perf_counter(SNRT_PERF_CNT0, SNRT_PERF_CNT_DMA_AR_BW, 0);
        snrt_start_perf_counter(SNRT_PERF_CNT1, SNRT_PERF_CNT_DMA_AW_BW, 0);

        // Transfer around some data
        uint32_t *dst = (void *)snrt_cluster_memory().start;
        uint32_t *src = (void *)snrt_global_memory().start +
                        0x4;  // Induce missaligned access
        printf("Transfering from %p to %p\n", src, dst);
        snrt_dma_txid_t txid_1d = snrt_dma_start_1d(dst, src, 128);
        snrt_dma_txid_t txid_2d = snrt_dma_start_2d(dst, src, 128, 128, 0, 4);

        // Wait until completion
        snrt_dma_wait_all();

        // Stop performance counter
        snrt_stop_perf_counter(SNRT_PERF_CNT0);
        snrt_stop_perf_counter(SNRT_PERF_CNT1);

        // Get performance counters
        read_bytes = snrt_get_perf_counter(SNRT_PERF_CNT0);
        write_bytes = snrt_get_perf_counter(SNRT_PERF_CNT1);
        printf("End: %d/%d bytes read, written\n", read_bytes, write_bytes);

        // Reset counter
        snrt_reset_perf_counter(SNRT_PERF_CNT0);
        snrt_reset_perf_counter(SNRT_PERF_CNT1);
    }

    snrt_cluster_hw_barrier();

    uint32_t tcdm_accesses, tcdm_congestion;

    if (core_idx == 0) {
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

    if (core_idx == 0) {
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
