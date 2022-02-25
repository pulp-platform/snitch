// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <math.h>

#include "conv2d.h"
#include "data_fusedconv.h"
#include "printf.h"
#include "snrt.h"
#include "utils.h"

void *share_ptr;

int main() {
    uint32_t ifmap_size = (k.dim_in_x + k.padding_x_left + k.padding_x_right) *
                          (k.dim_in_y + k.padding_y_top + k.padding_y_bottom) *
                          k.ch_in;
    uint32_t weights_size =
        k.dim_kernel_x * k.dim_kernel_y * k.ch_in * k.ch_out;
    uint32_t ofmap_size = k.dim_out_x * k.dim_out_y * k.ch_out;

    uint32_t total_size =
        ifmap_size + weights_size + k.ch_out + k.ch_out + ofmap_size;

    float *ptr;

    if (snrt_is_dm_core() == 0) {
        ptr = snrt_l1alloc(total_size * sizeof(float));
        share_ptr = ptr;
    }

    snrt_cluster_hw_barrier();

    ptr = share_ptr;

    float *pInBuffer = ptr;
    ptr += ifmap_size;
    float *pWeight = ptr;
    ptr += weights_size;
    float *kappa = ptr;
    ptr += k.ch_out;
    float *lambda = ptr;
    ptr += k.ch_out;
    float *pOutBuffer = ptr;
    ptr += ofmap_size;

    if (snrt_is_dm_core()) {
        snrt_dma_start_1d(pInBuffer, fusedconv_pInBuffer_dram,
                          ifmap_size * sizeof(float));
        snrt_dma_start_1d(pWeight, fusedconv_pWeight_dram,
                          weights_size * sizeof(float));
        snrt_dma_start_1d(pOutBuffer, fusedconv_pOutBuffer_dram,
                          ofmap_size * sizeof(float));
        snrt_dma_start_1d(kappa, fusedconv_kappa_dram,
                          sizeof(fusedconv_kappa_dram));
        snrt_dma_start_1d(lambda, fusedconv_lambda_dram,
                          sizeof(fusedconv_lambda_dram));
        snrt_dma_wait_all();
    }

    k.pInBuffer = pInBuffer;
    k.pWeight = pWeight;
    k.pOutBuffer = pOutBuffer;
    k.kappa = kappa;
    k.lambda = lambda;

    snrt_cluster_hw_barrier();

    for (int i = 0; i < 1; i++) {
        if (snrt_is_compute_core() || (snrt_cluster_core_num() == 1)) {
            if (dw) {
                benchmark_get_cycle();
                occamy_conv_dw_opt_fp32(&k);
                benchmark_get_cycle();

            } else if (chw_layer) {
                benchmark_get_cycle();
                occamy_conv_chw_opt_fp32(&k);
                benchmark_get_cycle();
            } else {
                benchmark_get_cycle();
                occamy_conv_opt_fp32(&k);
                benchmark_get_cycle();
            }

        } else {
            // conv kernel has 1 cluster barrier to synchronize
            snrt_cluster_hw_barrier();
        }
    }
    snrt_cluster_hw_barrier();

    uint32_t errors = 0;
    if (snrt_is_dm_core()) {
        // Output feature map (H x W x Co)
        const uint32_t output_w_stride = k.ch_out;
        const uint32_t output_h_stride = output_w_stride * k.dim_out_x;
        for (uint32_t i = 0; i < ofmap_size; i++) {
            if (fabs(pOutBuffer[i] -
                     ((float *)fusedconv_pCheckOutBuffer_dram)[i]) > 0.01) {
                errors++;
                printf("Error at h %d w %d co %d\n", i / output_h_stride,
                       (i % output_h_stride) / output_w_stride,
                       i % output_w_stride);
            }
        }
        printf("%d/%d Errors\n", errors, ofmap_size);
    }

    return errors;
}
