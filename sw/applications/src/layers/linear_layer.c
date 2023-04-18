// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "linear_layer.h"

#include "layer.h"
#include "linear.h"
#include "printf.h"
#include "snrt.h"

void linear_layer(const linear_layer_t *l) {

    uint32_t cluster_num = snrt_cluster_num();
    uint32_t cluster_id = snrt_cluster_idx();
    uint32_t compute_num = snrt_cluster_compute_core_num();
    uint32_t compute_id = snrt_cluster_compute_core_idx();

    uint32_t ifmap_size = l->CH * l->CW * sizeof(float);
    uint32_t weights_size = l->CO * l->CI * sizeof(float);
    uint32_t bias_size = l->CO * sizeof(float);
    uint32_t ofmap_size = l->CH * l->CO * sizeof(float);

    void *ptr = (float *)snrt_cluster_memory().start;
    float *ifmap = ptr;
    ptr += ifmap_size;
    float *weights = ptr;
    ptr += weights_size;
    float *bias = ptr;
    ptr += bias_size;
    float *ofmap = ptr;
    ptr += ofmap_size;

    // now we DMA transfer the weights and bias into the cluster TCDM
    if (snrt_is_dm_core()) {
        snrt_dma_txid_t txid_bias   = snrt_dma_start_1d(
                                    bias, l->bias, bias_size);
        snrt_dma_txid_t txid_weights = snrt_dma_start_2d(weights,
                                    l->weights, l->CO * sizeof(float),
                                    l->CO * sizeof(float), l->CO * sizeof(float),
                                    l->CI * sizeof(float));
        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    if (compute_id == 0) {
        // print the bias
        for (int i = 0; i < l->CO; i++) {
            printf("bias[%d] = %f\n", i, bias[i]);
            // print the weights
            for (int j = 0; j < l->CI; j++) {
                printf("weights[%d][%d] = %f\n", i, j, weights[i * l->CI + j]);
            }
        }

    }

}