// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"
#include "printf.h"
#include "utils.h"

#define DMA_1D_TRANSFER

int main() {

    uint32_t cluster_idx = snrt_cluster_idx();
    uint32_t cluster_num = snrt_cluster_num();

    uint32_t *l1_ptr = (void *)snrt_cluster_memory().start;
    uint32_t *global_ptr = (void *)snrt_global_memory().start;

    const uint32_t transfer_size = 32 * 1024; // 32KB
    const uint32_t burst_size = 64; // 512 Wide DMA bus
    const uint32_t num_transactions = transfer_size / burst_size;

    struct snrt_barrier *barr = (void *)snrt_global_memory().start;
    uint32_t num_synch_cores = cluster_num;

    int32_t src_cluster_idx_offset, src_quadrant_idx_offset;
    uint32_t *l1_ext_ptr;


    // Exit compute cores
    if (snrt_is_compute_core())
        return 0;

    // Test 1: single cluster 1D transfers from global to L1
    #define TEST1
    #ifdef TEST1
    snrt_dma_start_tracking();
    if (cluster_idx == 0) {
        #ifdef DMA_1D_TRANSFER
        snrt_dma_start_1d(l1_ptr, global_ptr, transfer_size);
        #else
        snrt_dma_start_2d(l1_ptr, global_ptr, burst_size, burst_size, burst_size, num_transactions);
        #endif
        snrt_dma_wait_all();
    }
    snrt_dma_stop_tracking();
    #endif

    snrt_barrier(barr, num_synch_cores);

    // Test 2: multi cluster 1D transfers from global to L1
    #define TEST2
    #ifdef TEST2
    snrt_dma_start_tracking();
    #ifdef DMA_1D_TRANSFER
    snrt_dma_start_1d(l1_ptr, global_ptr, transfer_size);
    #else
    snrt_dma_start_2d(l1_ptr, global_ptr, burst_size, burst_size, burst_size, num_transactions);
    #endif
    snrt_dma_wait_all();
    snrt_dma_stop_tracking();
    #endif

    snrt_barrier(barr, num_synch_cores);

    // Test 3: single L1 to L1 transfer of same quadrant
    #define TEST3
    #ifdef TEST3
    src_cluster_idx_offset = ((cluster_idx % 4) == 3)? -3 : 1;
    l1_ext_ptr = (void *)snrt_ext_cluster_memory(cluster_idx + src_cluster_idx_offset).start;
    snrt_dma_start_tracking();
    if (cluster_idx == 0) {
        #ifdef DMA_1D_TRANSFER
        snrt_dma_start_1d(l1_ptr, l1_ext_ptr, transfer_size);
        #else
        snrt_dma_start_2d(l1_ptr, l1_ext_ptr, burst_size, burst_size, burst_size, num_transactions);
        #endif
        snrt_dma_wait_all();
    }
    snrt_dma_stop_tracking();
    #endif

    snrt_barrier(barr, num_synch_cores);

    // Test 4: multi L1 to L1 transfer of same quadrant
    #define TEST4
    #ifdef TEST4
    src_cluster_idx_offset = ((cluster_idx % 4) == 3)? -3 : 1;
    l1_ext_ptr = (void *)snrt_ext_cluster_memory(cluster_idx + src_cluster_idx_offset).start;
    snrt_dma_start_tracking();
    #ifdef DMA_1D_TRANSFER
    snrt_dma_start_1d(l1_ptr, l1_ext_ptr, transfer_size);
    #else
    snrt_dma_start_2d(l1_ptr, l1_ext_ptr, burst_size, burst_size, burst_size, num_transactions);
    #endif
    snrt_dma_wait_all();
    snrt_dma_stop_tracking();
    #endif

    snrt_barrier(barr, num_synch_cores);

    // Test 5: single L1 to L1 transfer of different quadrant
    #define TEST5
    #ifdef TEST5
    src_quadrant_idx_offset = ((cluster_idx / 4) == 7)? -7 : 1;
    l1_ext_ptr = (void *)snrt_ext_cluster_memory(cluster_idx + src_quadrant_idx_offset * 4).start;
    snrt_dma_start_tracking();
    if (cluster_idx == 0) {
        #ifdef DMA_1D_TRANSFER
        snrt_dma_start_1d(l1_ptr, l1_ext_ptr, transfer_size);
        #else
        snrt_dma_start_2d(l1_ptr, l1_ext_ptr, burst_size, burst_size, burst_size, num_transactions);
        #endif
        snrt_dma_wait_all();
    }
    snrt_dma_stop_tracking();
    #endif

    snrt_barrier(barr, num_synch_cores);

    // Test 6: single L1 to L1 transfer of different quadrant
    #define TEST6
    #ifdef TEST6
    src_quadrant_idx_offset = ((cluster_idx / 4) == 7)? -7 : 1;
    l1_ext_ptr = (void *)snrt_ext_cluster_memory(cluster_idx + src_quadrant_idx_offset * 4).start;
    snrt_dma_start_tracking();
    #ifdef DMA_1D_TRANSFER
    snrt_dma_start_1d(l1_ptr, l1_ext_ptr, transfer_size);
    #else
    snrt_dma_start_2d(l1_ptr, l1_ext_ptr, burst_size, burst_size, burst_size, num_transactions);
    #endif
    snrt_dma_wait_all();
    snrt_dma_stop_tracking();
    #endif

    snrt_barrier(barr, num_synch_cores);

    return 0;
}
