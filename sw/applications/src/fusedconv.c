// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "data_fusedconv.h"
#include "conv2d.h"
#include "snrt.h"
#include "utils.h"
#include "printf.h"
#include <math.h>

int main() {

    float *ptr = (void *)snrt_cluster_memory().start;

    uint32_t ifmap_size = (dim_in_x + padding_x_left + padding_x_right) *
                          (dim_in_y + padding_y_top + padding_y_bottom) * ch_in;
    uint32_t weights_size = dim_kernel_x * dim_kernel_y * ch_in * ch_out;
    uint32_t ofmap_size = dim_out_x * dim_out_y * ch_out;


    float *pInBuffer = ptr;
    ptr += ifmap_size;
    float *pWeight = ptr;
    ptr += weights_size;
    float *k = ptr;
    ptr += ch_out;
    float *lambda = ptr;
    ptr += ch_out;
    float *pOutBuffer = ptr;
    ptr += ofmap_size;

    if (ptr >= snrt_cluster_memory().end) {
        printf("Not enough TCDM memory to store tile\n");
        return 1;
    }

    if (snrt_is_dm_core()) {
        snrt_dma_start_1d(pInBuffer, fusedconv_pInBuffer_dram,
                          ifmap_size * sizeof(float));
        snrt_dma_start_1d(pWeight, fusedconv_pWeight_dram,
                          weights_size * sizeof(float));
        snrt_dma_start_1d(pOutBuffer, fusedconv_pOutBuffer_dram, ofmap_size * sizeof(float));
        snrt_dma_start_1d(k, k_dram, sizeof(k_dram));
        snrt_dma_start_1d(lambda, lambda_dram, sizeof(lambda_dram));
        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    if (snrt_is_compute_core()) {

        benchmark_get_cycle();

        occamy_conv_opt_fp32(pInBuffer, dim_in_x, dim_in_y, ch_in, pWeight, ch_out,
                        dim_kernel_x, dim_kernel_y, padding_y_top, padding_y_bottom,
                        padding_x_left, padding_x_right, stride_x, stride_y, bias,
                        bias_shift, out_shift, out_mult, pOutBuffer, dim_out_x,
                        dim_out_y, k, lambda, pIm2ColBuffer, flag_relu,
                        flag_batch_norm, flag_y_accumulate_start,
                        flag_y_accumulate_end, memory_chan);

        benchmark_get_cycle();

    } else {
        // conv kernel has 1 cluster barrier to synchronize
        snrt_cluster_hw_barrier();
    }
    snrt_cluster_hw_barrier();

    uint32_t errors = 0;
    if (snrt_is_dm_core()) {
        // Output feature map (H x W x Co)
        const uint32_t output_w_stride = ch_out;
        const uint32_t output_h_stride = output_w_stride * dim_out_x;
        for (uint32_t i = 0; i < ofmap_size; i++) {
            if (fabs(pOutBuffer[i] - ((float *)fusedconv_pCheckOutBuffer_dram)[i]) > 0.01) {
                errors++;
                // printf("Error at h %d w %d co %d\n", i / output_h_stride, (i % output_h_stride) / output_w_stride, i % output_w_stride);
            }
        }
        printf("%d/%d Errors\n", errors, ofmap_size);
    }


    return errors;
}
