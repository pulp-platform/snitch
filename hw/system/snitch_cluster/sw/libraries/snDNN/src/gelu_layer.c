// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "gelu_layer.h"

#include "gelu.h"
#include "layer.h"
// #include "printf.h"
#include "snrt.h"

void gelu_layer(const gelu_layer_t *l) {
    uint32_t cluster_num = snrt_cluster_num();
    uint32_t cluster_id = snrt_cluster_idx();
    uint32_t compute_num = snrt_cluster_compute_core_num();
    uint32_t compute_id = snrt_cluster_compute_core_num();

    uint32_t ifmap_size =
        l->BATCH_SIZE * l->SEQ_LEN * l->HIDDEN_NODES * sizeof(float);
    uint32_t ofmap_size = ifmap_size;

    void *ptr = (float *)snrt_l1_next();
    float *ifmap = ptr;
    ptr += ifmap_size;
    float *ofmap = ptr;
    ptr += ofmap_size;

    // DMA transfer the ifmap into the cluster TCDM
    if (snrt_is_dm_core()) {
        snrt_dma_txid_t txid_ifmap = snrt_dma_start_2d(
            ifmap, l->ifmap, l->BATCH_SIZE * sizeof(float),
            l->BATCH_SIZE * sizeof(float), l->BATCH_SIZE * sizeof(float),
            l->SEQ_LEN * l->HIDDEN_NODES * sizeof(float));

        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    if (snrt_is_compute_core() &&
        snrt_cluster_compute_core_num() < compute_num) {
        // determine the row offset for each core
        int32_t row_offset = compute_id * l->HIDDEN_NODES;

        // determine the row stride of each matrix
        int32_t ldI = compute_num * l->HIDDEN_NODES;

        // determine the batch offset for each core
        int32_t batch_offset = l->SEQ_LEN * l->HIDDEN_NODES;

        // printf("row_offset: %d, ldI: %d\n", row_offset, ldI);

        for (int b = 0; b < l->BATCH_SIZE; b++) {
            // if (compute_id == 1) {
            //     printf("BATCH: %d\n", b);
            // }
            gelu_fp32(&ifmap[row_offset + b * batch_offset],
                      &ofmap[row_offset + b * batch_offset], ldI, l->BATCH_SIZE,
                      l->SEQ_LEN / 8, l->HIDDEN_NODES);
        }

        snrt_cluster_hw_barrier();

    } else {
        snrt_cluster_hw_barrier();
    }

    snrt_global_barrier();
}