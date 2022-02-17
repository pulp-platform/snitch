// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <math.h>

#include "conv2d.h"
#include "data_fusedconv.h"
#include "printf.h"
#include "snrt.h"
#include "utils.h"

int main() {
    uint32_t ifmap_size = (dim_in_x + padding_x_left + padding_x_right) *
                          (dim_in_y + padding_y_top + padding_y_bottom) * ch_in;
    uint32_t weights_size = dim_kernel_x * dim_kernel_y * ch_in * ch_out;
    uint32_t ofmap_size = dim_out_x * dim_out_y * ch_out;

    uint32_t total_size =
        ifmap_size + weights_size + ch_out + ch_out + ofmap_size;

    void *ptr = snrt_l1alloc(total_size * sizeof(float));

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

    // printf("Core %d/%d is com/dma core %d/%d\n", snrt_cluster_core_idx(),
    // snrt_cluster_core_num(), snrt_is_compute_core(), snrt_is_dm_core());

    if (snrt_is_dm_core()) {
        snrt_dma_start_1d(pInBuffer, fusedconv_pInBuffer_dram,
                          ifmap_size * sizeof(float));
        snrt_dma_start_1d(pWeight, fusedconv_pWeight_dram,
                          weights_size * sizeof(float));
        snrt_dma_start_1d(pOutBuffer, fusedconv_pOutBuffer_dram,
                          ofmap_size * sizeof(float));
        snrt_dma_start_1d(k, k_dram, sizeof(k_dram));
        snrt_dma_start_1d(lambda, lambda_dram, sizeof(lambda_dram));
        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    for (int i = 0; i < 1; i++) {
        if (snrt_is_compute_core() || (snrt_cluster_core_num() == 1)) {
            if (dw) {
                benchmark_get_cycle();

                occamy_conv_dw_opt_fp32(
                    pInBuffer, dim_in_x, dim_in_y, ch_in, pWeight, ch_out,
                    dim_kernel_x, dim_kernel_y, padding_y_top, padding_y_bottom,
                    padding_x_left, padding_x_right, stride_x, stride_y, bias,
                    bias_shift, out_shift, out_mult, pOutBuffer, dim_out_x,
                    dim_out_y, k, lambda, pIm2ColBuffer, flag_relu,
                    flag_batch_norm, flag_y_accumulate_start,
                    flag_y_accumulate_end, memory_chan);

                benchmark_get_cycle();

            } else if (chw_layer) {
                benchmark_get_cycle();

                occamy_conv_chw_opt_fp32(
                    pInBuffer, dim_in_x, dim_in_y, ch_in, pWeight, ch_out,
                    dim_kernel_x, dim_kernel_y, padding_y_top, padding_y_bottom,
                    padding_x_left, padding_x_right, stride_x, stride_y, bias,
                    bias_shift, out_shift, out_mult, pOutBuffer, dim_out_x,
                    dim_out_y, k, lambda, pIm2ColBuffer, flag_relu,
                    flag_batch_norm, flag_y_accumulate_start,
                    flag_y_accumulate_end, memory_chan);

                benchmark_get_cycle();
            } else {
                benchmark_get_cycle();

                occamy_conv_opt_fp32(
                    pInBuffer, dim_in_x, dim_in_y, ch_in, pWeight, ch_out,
                    dim_kernel_x, dim_kernel_y, padding_y_top, padding_y_bottom,
                    padding_x_left, padding_x_right, stride_x, stride_y, bias,
                    bias_shift, out_shift, out_mult, pOutBuffer, dim_out_x,
                    dim_out_y, k, lambda, pIm2ColBuffer, flag_relu,
                    flag_batch_norm, flag_y_accumulate_start,
                    flag_y_accumulate_end, memory_chan);

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
        const uint32_t output_w_stride = ch_out;
        const uint32_t output_h_stride = output_w_stride * dim_out_x;
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
