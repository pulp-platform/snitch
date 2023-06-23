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
    uint32_t compute_id = snrt_cluster_compute_core_num();

    uint32_t ifmap_size = l->CH * l->CW * sizeof(float);
    uint32_t weights_size = l->CO * l->CI * sizeof(float);
    uint32_t bias_size = l->CO * sizeof(float);
    uint32_t ofmap_size = l->CH * l->CO * sizeof(float);

    void *ptr = (float *)snrt_l1_next();
    float *ifmap = ptr;
    ptr += ifmap_size;
    float *weights = ptr;
    ptr += weights_size;
    float *bias = ptr;
    ptr += bias_size;
    float *ofmap = ptr;
    ptr += ofmap_size;
    float *result = ptr;
    ptr += ofmap_size;

    // now we DMA transfer the weights and bias into the cluster TCDM
    if (snrt_is_dm_core()) {
        snrt_dma_txid_t txid_bias = snrt_dma_start_1d(bias, l->bias, bias_size);
        snrt_dma_txid_t txid_weights = snrt_dma_start_2d(
            weights, l->weights, l->CO * sizeof(float), l->CO * sizeof(float),
            l->CO * sizeof(float), l->CI * sizeof(float));

        snrt_dma_txid_t txid_ifmap = snrt_dma_start_2d(
            ifmap, l->ifmap, l->CH * sizeof(float), l->CH * sizeof(float),
            l->CH * sizeof(float), l->CW * sizeof(float));

        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    if (snrt_is_compute_core() &&
        snrt_cluster_compute_core_num() < compute_num) {
        // determine the row stride of each matrix
        int32_t ldI = l->CH * l->CW;
        int32_t ldW = compute_num * l->CO;
        int32_t ldB = compute_num;
        int32_t ldO = ldB;

        // determine the row offset of each matrix
        int32_t offW = compute_id * l->CO;
        int32_t offB = compute_id;
        int32_t offO = compute_id;

        // printf("compute_id = %d, offW = %d, offB = %d, offO = %d\n",
        //         compute_id, offW, offB, offO);

        linear_fp32(ifmap, ldI, &weights[offW], ldW, &bias[compute_id], ldB,
                    ofmap, ldO, l->CI, l->CO / compute_num, l->CH);

    } else {
        snrt_cluster_hw_barrier();
    }

    snrt_cluster_hw_barrier();

    if (snrt_is_dm_core()) {
        snrt_dma_txid_t txid_result = snrt_dma_start_2d(
            result, l->result, l->CH * sizeof(float), l->CH * sizeof(float),
            l->CH * sizeof(float), l->CO * sizeof(float));
        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    // TODO: fix this, wrong values for ofmap printed
    if (compute_id == 0) {
        // compare result with ofmap
        float tolerance = 1e-6;
        int error = 0;
        for (int i = 0; i < l->CH; i++) {
            for (int j = 0; j < l->CO; j++) {
                if (result[i * l->CO + j] - ofmap[i * l->CO + j] > tolerance) {
                    printf(
                        "MISMATCH: result[%d][%d] = %f, ofmap[%d][%d] = %f\n",
                        i, j, result[i * l->CO + j], i, j,
                        ofmap[i * l->CO + j]);
                    error += 1;
                }
            }
        }

        printf("[%d/%d] mismatches\n", error, l->CH * l->CO);
    }
}