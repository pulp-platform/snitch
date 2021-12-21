// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "conv2d.h"
#include "printf.h"

void __attribute__((noinline)) occamy_conv_opt(
    const double* pInBuffer, const uint16_t dim_in_x, const uint16_t dim_in_y,
    const uint16_t ch_in, const double* pWeight, const uint16_t ch_out,
    const uint16_t dim_kernel_x, const uint16_t dim_kernel_y,
    const uint16_t padding_y_top, const uint16_t padding_y_bottom,
    const uint16_t padding_x_left, const uint16_t padding_x_right,
    const uint16_t stride_x, const uint16_t stride_y, const int8_t* bias,
    const uint16_t bias_shift, const uint16_t out_shift,
    const uint16_t out_mult, double* pOutBuffer, const uint16_t dim_out_x,
    const uint16_t dim_out_y, double* k, double* lambda, double* pIm2ColBuffer,
    int flag_relu, int flag_batch_norm, int flag_y_accumulate_start,
    int flag_y_accumulate_end, unsigned int* memory_chan) {
    // Parallelization/Pipelining parameters
    const uint32_t compute_id = snrt_cluster_compute_core_idx();
    const uint32_t compute_num = snrt_cluster_compute_core_num();
    const uint32_t n_unroll = 8;  // Must be at least 6

    // Calculate strides to access specific dimensions
    // of input/output feature map and weights
    // Input feature map (H x W x Ci)
    // Calculate effective H, W dimension including padding
    const uint32_t dim_in_eff_x = dim_in_x + padding_x_left + padding_x_right;
    const uint32_t dim_in_eff_y = dim_in_y + padding_y_top + padding_y_bottom;
    const uint32_t input_w_stride = ch_in;
    const uint32_t input_h_stride = input_w_stride * dim_in_eff_x;

    // Output feature map (H x W x Co)
    const uint32_t output_w_stride = ch_out;
    const uint32_t output_h_stride = output_w_stride * dim_out_x;

    // Weight (Co x Fh x Fw x Ci)
    const uint32_t kernel_w_stride = ch_in;
    const uint32_t kernel_h_stride = kernel_w_stride * dim_kernel_x;
    const uint32_t kernel_co_stride = kernel_h_stride * dim_kernel_y;

    // Reference Loops
    // for (uint32_t co = compute_id; co < ch_out; co += compute_num) {
    //     for (uint32_t h0 = 0; h0 < dim_in_y / n_unroll; h++) {
    //         for (uint32_t w = 0; w < dim_in_x; w += stride_x) {
    //             for (uint32_t fh = 0; fh < dim_kernel_y, fh++) {
    //                 for (uint32_t fw = 0; fw < dim_kernel_x, fw++) {
    //                     for (uint32_t ci = 0; ci < ch_in; ci++) {
    //                         for (uint32_t h1 = 0; h1 < n_unroll; h1++) {
    //                             pOutBuffer[(h-pad_t)/str_y][(w-pad_l)/str_x][co]
    //                                   +=  pInBuffer[h+fh][w+fw][ci] *
    //                                       pWeightBuffer[co][fh][fw][ci]
    //                         }
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }

    // Setup SSRs bounds and strides for input feature map
    const uint32_t ssr0_b[4] = {n_unroll, ch_in, dim_kernel_x, dim_kernel_y};
    const uint32_t ssr0_i[4] = {
        input_h_stride * sizeof(double), 1 * sizeof(double),
        input_w_stride * sizeof(double), input_h_stride * sizeof(double)};

    snrt_ssr_loop_4d(SNRT_SSR_DM0, ssr0_b[0], ssr0_b[1], ssr0_b[2], ssr0_b[3],
                     ssr0_i[0], ssr0_i[1], ssr0_i[2], ssr0_i[3]);

    // Setup SSRs bounds and strides for kernel
    // We use only 3D SSRs here as the inner most dimension is repeated
    const uint32_t ssr1_b[3] = {ch_in, dim_kernel_x, dim_kernel_y};
    const uint32_t ssr1_i[3] = {1 * sizeof(double),
                                kernel_w_stride * sizeof(double),
                                kernel_h_stride * sizeof(double)};

    snrt_ssr_loop_3d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2], ssr1_i[0],
                     ssr1_i[1], ssr1_i[2]);

    snrt_ssr_repeat(SNRT_SSR_DM1, n_unroll);

    // Output channel dimension `ch_out` is parallelized over cores
    for (uint32_t co = compute_id; co < ch_out; co += compute_num) {
        // Input height dimension `dim_in_eff_y` first split
        for (uint32_t h0 = 0; h0 < dim_in_eff_y / n_unroll; h0++) {
            // TODO: clean up left-over columns

            // Input width dimension `dim_in_x`
            for (uint32_t w = 0; w < dim_in_x; w += stride_x) {
                // TODO: check if initialization needs to be unrolled by hand
                register double sum[n_unroll];
                if (flag_y_accumulate_start) {
                    for (uint32_t i = 0; i < n_unroll; i++) {
                        sum[i] = 0.0;
                    }
                } else {
                    for (uint32_t i = 0; i < n_unroll; i++) {
                        sum[i] = *(pOutBuffer + (h0 * n_unroll + i) * output_h_stride +
                                  w * output_w_stride + co);
                    }
                }

                // SSR address setup and enable
                snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_4D,
                              (void *)(pInBuffer + h0 * n_unroll * input_h_stride +
                                  w * input_w_stride));
                snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_3D,
                              (void *)(pWeight + co * kernel_co_stride));
                snrt_ssr_enable();

                asm volatile(
                    "frep.o %[n_frep], 8, 0, 0 \n"
                    "fmadd.d %[sum0], ft0, ft1, %[sum0] \n"
                    "fmadd.d %[sum1], ft0, ft1, %[sum1] \n"
                    "fmadd.d %[sum2], ft0, ft1, %[sum2] \n"
                    "fmadd.d %[sum3], ft0, ft1, %[sum3] \n"
                    "fmadd.d %[sum4], ft0, ft1, %[sum4] \n"
                    "fmadd.d %[sum5], ft0, ft1, %[sum5] \n"
                    "fmadd.d %[sum6], ft0, ft1, %[sum6] \n"
                    "fmadd.d %[sum7], ft0, ft1, %[sum7] \n"
                    : [sum0] "+f"(sum[0]), [sum1] "+f"(sum[1]), [sum2] "+f"(sum[2]),
                      [sum3] "+f"(sum[3]), [sum4] "+f"(sum[4]), [sum5] "+f"(sum[5]),
                      [sum6] "+f"(sum[6]), [sum7] "+f"(sum[7])
                    : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in - 1)
                    : "ft0", "ft1");


                // // Kernel y dimension `dim_kernel_y`
                // for (uint32_t fh = 0; fh < dim_kernel_y, fh++) {
                //     // Kernel x dimension `dim_kernel_x`
                //     for (uint32_t fw = 0; fw < dim_kernel_x, fw++) {
                //         // Input channel dimension `ch_in`
                //         for (uint32_t ci = 0; ci < ch_in; ci++) {
                //             // Input height dimension `dim_in_y` 2nd split is
                //             // unrolled, weight value can be repeated for
                //             // `n_unroll` times in the most inner loop which is
                //             // beneficial for banking conflicts
                //             for (uint32_t h1 = 0; h1 < n_unroll; h1++) {
                //                 // Most inner loop
                //                 // pOutBuffer[(h-pad_t)/str_y][(w-pad_l)/str_x][co]
                //                 //      +=  pInBuffer[h+fh][w+fw][ci] *
                //                 //          pWeightBuffer[co][fh][fw][ci]
                //             }
                //         }
                //     }
                // }

                snrt_ssr_disable();

                // TODO: Check if needs to be unrolled manually
                // printf("co %d, h0 %d w %d\n", co, h0, w);
                for (uint32_t i = 0; i < n_unroll; i++) {
                    pOutBuffer[(h0 * n_unroll + i) * output_h_stride + w * output_w_stride + co] = sum[i];
                }
            }
        }
    }
}
