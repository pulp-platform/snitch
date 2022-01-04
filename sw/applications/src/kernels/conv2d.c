// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "conv2d.h"

#include "printf.h"

typedef float v2f32 __attribute__((vector_size(8)));

typedef union {
    double f64;
    v2f32 vec;
} v2s;

void __attribute__((noinline)) occamy_conv_opt_fp64(
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
    const uint32_t max_unroll = 8;  // Maximum number of unrolling
    const uint32_t cleanup_unroll = dim_out_y % max_unroll;

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
    //     for (uint32_t h0 = 0; h0 < dim_in_y / max_unroll; h++) {
    //         for (uint32_t w = 0; w < dim_in_x; w += stride_x) {
    //             for (uint32_t fh = 0; fh < dim_kernel_y, fh++) {
    //                 for (uint32_t fw = 0; fw < dim_kernel_x, fw++) {
    //                     for (uint32_t ci = 0; ci < ch_in; ci++) {
    //                         for (uint32_t h1 = 0; h1 < max_unroll; h1++) {
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
    const uint32_t ssr0_b[4] = {max_unroll, ch_in, dim_kernel_x, dim_kernel_y};
    const uint32_t ssr0_i[4] = {
        input_h_stride * stride_y * sizeof(double), 1 * sizeof(double),
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

    snrt_ssr_repeat(SNRT_SSR_DM1, max_unroll);

    // Output channel dimension `ch_out` is parallelized over cores
    for (uint32_t co = compute_id; co < ch_out; co += compute_num) {
        uint32_t h0 = 0;

        // If `dim_out_y` is not divisible by `unroll`, we have to clean up at
        // the end which modifies the SSR loops, thus initialize it again
        // correctly
        if (cleanup_unroll) {
            snrt_ssr_loop_4d(SNRT_SSR_DM0, ssr0_b[0], ssr0_b[1], ssr0_b[2],
                             ssr0_b[3], ssr0_i[0], ssr0_i[1], ssr0_i[2],
                             ssr0_i[3]);

            snrt_ssr_loop_3d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2],
                             ssr1_i[0], ssr1_i[1], ssr1_i[2]);

            snrt_ssr_repeat(SNRT_SSR_DM1, max_unroll);
        }

        // Output height dimension `dim_out_y` first split
        for (h0 = 0; h0 < dim_out_y / max_unroll; h0++) {
            // Output width dimension `dim_out_x`
            for (uint32_t w = 0; w < dim_out_x; w++) {
                // TODO: check if initialization needs to be unrolled by hand
                register double sum[max_unroll];
                if (flag_y_accumulate_start) {
                    for (uint32_t i = 0; i < max_unroll; i++) {
                        sum[i] = 0.0;
                    }
                } else {
                    for (uint32_t i = 0; i < max_unroll; i++) {
                        sum[i] = *(pOutBuffer +
                                   (h0 * max_unroll + i) * output_h_stride +
                                   w * output_w_stride + co);
                    }
                }

                // SSR address setup and enable
                snrt_ssr_read(
                    SNRT_SSR_DM0, SNRT_SSR_4D,
                    (void*)(pInBuffer +
                            h0 * max_unroll * stride_y * input_h_stride +
                            w * stride_x * input_w_stride));
                snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_3D,
                              (void*)(pWeight + co * kernel_co_stride));
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
                    : [sum0] "+f"(sum[0]), [sum1] "+f"(sum[1]),
                      [sum2] "+f"(sum[2]), [sum3] "+f"(sum[3]),
                      [sum4] "+f"(sum[4]), [sum5] "+f"(sum[5]),
                      [sum6] "+f"(sum[6]), [sum7] "+f"(sum[7])
                    : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in - 1)
                    : "ft0", "ft1", "ft2");

                snrt_ssr_disable();

                // TODO: Check if needs to be unrolled manually
                for (uint32_t i = 0; i < max_unroll; i++) {
                    pOutBuffer[(h0 * max_unroll + i) * output_h_stride +
                               w * output_w_stride + co] = sum[i];
                }
            }
        }

        // Clean up rows
        if (cleanup_unroll) {
            // Modify most inner loop unrolling
            snrt_ssr_loop_4d(SNRT_SSR_DM0, cleanup_unroll, ssr0_b[1], ssr0_b[2],
                             ssr0_b[3], ssr0_i[0], ssr0_i[1], ssr0_i[2],
                             ssr0_i[3]);

            snrt_ssr_loop_3d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2],
                             ssr1_i[0], ssr1_i[1], ssr1_i[2]);

            snrt_ssr_repeat(SNRT_SSR_DM1, cleanup_unroll);

            // Output width dimension `dim_out_x`
            for (uint32_t w = 0; w < dim_out_x; w++) {
                register double sum[max_unroll];
                if (flag_y_accumulate_start) {
                    for (uint32_t i = 0; i < cleanup_unroll; i++) {
                        sum[i] = 0.0;
                    }
                } else {
                    for (uint32_t i = 0; i < cleanup_unroll; i++) {
                        sum[i] = *(pOutBuffer +
                                   (h0 * max_unroll + i) * output_h_stride +
                                   w * output_w_stride + co);
                    }
                }

                // SSR address setup and enable
                snrt_ssr_read(
                    SNRT_SSR_DM0, SNRT_SSR_4D,
                    (void*)(pInBuffer +
                            h0 * max_unroll * stride_y * input_h_stride +
                            w * stride_x * input_w_stride));
                snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_3D,
                              (void*)(pWeight + co * kernel_co_stride));
                snrt_ssr_enable();

                switch (cleanup_unroll) {
                    case 7:
                        asm volatile(
                            "frep.o %[n_frep], 7, 0, 0 \n"
                            "fmadd.d %[sum0], ft0, ft1, %[sum0] \n"
                            "fmadd.d %[sum1], ft0, ft1, %[sum1] \n"
                            "fmadd.d %[sum2], ft0, ft1, %[sum2] \n"
                            "fmadd.d %[sum3], ft0, ft1, %[sum3] \n"
                            "fmadd.d %[sum4], ft0, ft1, %[sum4] \n"
                            "fmadd.d %[sum5], ft0, ft1, %[sum5] \n"
                            "fmadd.d %[sum6], ft0, ft1, %[sum6] \n"
                            : [sum0] "+f"(sum[0]), [sum1] "+f"(sum[1]),
                              [sum2] "+f"(sum[2]), [sum3] "+f"(sum[3]),
                              [sum4] "+f"(sum[4]), [sum5] "+f"(sum[5]),
                              [sum6] "+f"(sum[6])
                            : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in -
                                           1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 6:
                        asm volatile(
                            "frep.o %[n_frep], 6, 0, 0 \n"
                            "fmadd.d %[sum0], ft0, ft1, %[sum0] \n"
                            "fmadd.d %[sum1], ft0, ft1, %[sum1] \n"
                            "fmadd.d %[sum2], ft0, ft1, %[sum2] \n"
                            "fmadd.d %[sum3], ft0, ft1, %[sum3] \n"
                            "fmadd.d %[sum4], ft0, ft1, %[sum4] \n"
                            "fmadd.d %[sum5], ft0, ft1, %[sum5] \n"
                            : [sum0] "+f"(sum[0]), [sum1] "+f"(sum[1]),
                              [sum2] "+f"(sum[2]), [sum3] "+f"(sum[3]),
                              [sum4] "+f"(sum[4]), [sum5] "+f"(sum[5])
                            : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in -
                                           1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 5:
                        asm volatile(
                            "frep.o %[n_frep], 5, 0, 0 \n"
                            "fmadd.d %[sum0], ft0, ft1, %[sum0] \n"
                            "fmadd.d %[sum1], ft0, ft1, %[sum1] \n"
                            "fmadd.d %[sum2], ft0, ft1, %[sum2] \n"
                            "fmadd.d %[sum3], ft0, ft1, %[sum3] \n"
                            "fmadd.d %[sum4], ft0, ft1, %[sum4] \n"
                            : [sum0] "+f"(sum[0]), [sum1] "+f"(sum[1]),
                              [sum2] "+f"(sum[2]), [sum3] "+f"(sum[3]),
                              [sum4] "+f"(sum[4])
                            : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in -
                                           1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 4:
                        asm volatile(
                            "frep.o %[n_frep], 4, 0, 0 \n"
                            "fmadd.d %[sum0], ft0, ft1, %[sum0] \n"
                            "fmadd.d %[sum1], ft0, ft1, %[sum1] \n"
                            "fmadd.d %[sum2], ft0, ft1, %[sum2] \n"
                            "fmadd.d %[sum3], ft0, ft1, %[sum3] \n"
                            : [sum0] "+f"(sum[0]), [sum1] "+f"(sum[1]),
                              [sum2] "+f"(sum[2]), [sum3] "+f"(sum[3])
                            : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in -
                                           1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 3:
                        asm volatile(
                            "frep.o %[n_frep], 3, 0, 0 \n"
                            "fmadd.d %[sum0], ft0, ft1, %[sum0] \n"
                            "fmadd.d %[sum1], ft0, ft1, %[sum1] \n"
                            "fmadd.d %[sum2], ft0, ft1, %[sum2] \n"
                            : [sum0] "+f"(sum[0]), [sum1] "+f"(sum[1]),
                              [sum2] "+f"(sum[2])
                            : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in -
                                           1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 2:
                        asm volatile(
                            "frep.o %[n_frep], 2, 0, 0 \n"
                            "fmadd.d %[sum0], ft0, ft1, %[sum0] \n"
                            "fmadd.d %[sum1], ft0, ft1, %[sum1] \n"
                            : [sum0] "+f"(sum[0]), [sum1] "+f"(sum[1])
                            : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in -
                                           1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 1:
                        asm volatile(
                            "frep.o %[n_frep], 1, 0, 0 \n"
                            "fmadd.d %[sum0], ft0, ft1, %[sum0] \n"
                            : [sum0] "+f"(sum[0])
                            : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in -
                                           1)
                            : "ft0", "ft1", "ft2");
                        break;
                }

                snrt_ssr_disable();

                // TODO: Check if needs to be unrolled manually
                for (uint32_t i = 0; i < cleanup_unroll; i++) {
                    pOutBuffer[(h0 * max_unroll + i) * output_h_stride +
                               w * output_w_stride + co] = sum[i];
                }
            }
        }
    }

    snrt_cluster_hw_barrier();

    if (flag_batch_norm | flag_relu) {
        snrt_ssr_loop_2d(SNRT_SSR_DM0, dim_out_x * dim_out_y,
                         ch_out / compute_num, sizeof(double) * ch_out,
                         sizeof(double));
        snrt_ssr_loop_2d(SNRT_SSR_DM1, dim_out_x * dim_out_y,
                         ch_out / compute_num, sizeof(double) * ch_out,
                         sizeof(double));
        snrt_ssr_repeat(SNRT_SSR_DM1, 1);

        snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_2D, &pOutBuffer[compute_id]);
        snrt_ssr_write(SNRT_SSR_DM1, SNRT_SSR_2D, &pOutBuffer[compute_id]);

        snrt_ssr_enable();

        for (uint32_t co = compute_id; co < ch_out; co += compute_num) {
            register double current_lambda = lambda[co];
            register double current_k = k[co];
            register double zero = 0.0;

            register double tmp;

            if (flag_batch_norm && flag_relu) {
                asm volatile(
                    "frep.o %[n_frep], 2, 0, 0\n"
                    "fmadd.d $[tmp], ft0, %[k] %[l]\n"
                    "fmax.d ft1, %[tmp], %[zero]\n"
                    : [tmp] "+f"(tmp)
                    : [k] "f"(current_k), [l] "f"(current_lambda),
                      [zero] "f"(zero), [n_frep] "r"(dim_out_x * dim_out_y - 1)
                    : "ft0", "ft1", "ft2");
            } else if (flag_batch_norm && !flag_relu) {
                asm volatile(
                    "frep.o %[n_frep], 1, 0, 0\n"
                    "fmadd.d $[tmp], ft0, %[k] %[l]\n"
                    : [tmp] "+f"(tmp), [k] "+f"(current_k),
                      [l] "+f"(current_lambda)
                    : [n_frep] "r"(dim_out_x * dim_out_y - 1)
                    : "ft0", "ft1", "ft2");
            } else if (!flag_batch_norm && flag_relu) {
                asm volatile(
                    "frep.o %[n_frep], 1, 0, 0 \n"
                    "fmax.d ft1, ft0, %[zero]\n" ::[zero] "f"(zero),
                    [n_frep] "r"(dim_out_x * dim_out_y - 1)
                    : "ft0", "ft1", "ft2");
            }
        }

        snrt_ssr_disable();
    }
}

void __attribute__((noinline)) occamy_conv_opt_fp32(
    const float* pInBuffer, const uint16_t dim_in_x, const uint16_t dim_in_y,
    const uint16_t ch_in, const float* pWeight, const uint16_t ch_out,
    const uint16_t dim_kernel_x, const uint16_t dim_kernel_y,
    const uint16_t padding_y_top, const uint16_t padding_y_bottom,
    const uint16_t padding_x_left, const uint16_t padding_x_right,
    const uint16_t stride_x, const uint16_t stride_y, const int8_t* bias,
    const uint16_t bias_shift, const uint16_t out_shift,
    const uint16_t out_mult, float* pOutBuffer, const uint16_t dim_out_x,
    const uint16_t dim_out_y, float* k, float* lambda, float* pIm2ColBuffer,
    int flag_relu, int flag_batch_norm, int flag_y_accumulate_start,
    int flag_y_accumulate_end, unsigned int* memory_chan) {
    // Parallelization/Pipelining parameters
    const uint32_t compute_id = snrt_cluster_compute_core_idx();
    const uint32_t compute_num = snrt_cluster_compute_core_num();
    const uint32_t max_unroll = 8;  // Maximum number of unrolling
    const uint32_t cleanup_unroll = dim_out_y % max_unroll;

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
    //     for (uint32_t h0 = 0; h0 < dim_in_y / max_unroll; h++) {
    //         for (uint32_t w = 0; w < dim_in_x; w += stride_x) {
    //             for (uint32_t fh = 0; fh < dim_kernel_y, fh++) {
    //                 for (uint32_t fw = 0; fw < dim_kernel_x, fw++) {
    //                     for (uint32_t ci = 0; ci < ch_in; ci++) {
    //                         for (uint32_t h1 = 0; h1 < max_unroll; h1++) {
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
    const uint32_t ssr0_b[4] = {max_unroll, ch_in / 2, dim_kernel_x,
                                dim_kernel_y};
    const uint32_t ssr0_i[4] = {input_h_stride * stride_y * sizeof(float),
                                1 * sizeof(v2s), input_w_stride * sizeof(float),
                                input_h_stride * sizeof(float)};

    snrt_ssr_loop_4d(SNRT_SSR_DM0, ssr0_b[0], ssr0_b[1], ssr0_b[2], ssr0_b[3],
                     ssr0_i[0], ssr0_i[1], ssr0_i[2], ssr0_i[3]);

    // Setup SSRs bounds and strides for kernel
    // We use only 3D SSRs here as the inner most dimension is repeated
    const uint32_t ssr1_b[3] = {ch_in / 2, dim_kernel_x, dim_kernel_y};
    const uint32_t ssr1_i[3] = {1 * sizeof(v2s),
                                kernel_w_stride * sizeof(float),
                                kernel_h_stride * sizeof(float)};

    snrt_ssr_loop_3d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2], ssr1_i[0],
                     ssr1_i[1], ssr1_i[2]);

    // Repeat the innermost value `max_unroll` times
    snrt_ssr_repeat(SNRT_SSR_DM1, max_unroll);

    // Output channel dimension `ch_out` is parallelized over cores
    for (uint32_t co = compute_id; co < ch_out; co += compute_num) {
        uint32_t h0 = 0;

        // If `dim_out_y` is not divisible by `unroll`, we have to clean up at
        // the end which modifies the SSR loops, thus initialize it again
        // correctly
        if (cleanup_unroll) {
            snrt_ssr_loop_4d(SNRT_SSR_DM0, ssr0_b[0], ssr0_b[1], ssr0_b[2],
                             ssr0_b[3], ssr0_i[0], ssr0_i[1], ssr0_i[2],
                             ssr0_i[3]);

            snrt_ssr_loop_3d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2],
                             ssr1_i[0], ssr1_i[1], ssr1_i[2]);

            snrt_ssr_repeat(SNRT_SSR_DM1, max_unroll);
        }

        // Output height dimension `dim_out_y` first split
        for (h0 = 0; h0 < dim_out_y / max_unroll; h0++) {
            // Output width dimension `dim_out_x`
            for (uint32_t w = 0; w < dim_out_x; w++) {
                register v2s sum[max_unroll];
                register float reduce_reg[max_unroll];
                // pointer to output buffer location where intermediate values
                // are read from and stored
                float* _pOutBuffer =
                    &pOutBuffer[(h0 * max_unroll) * output_h_stride +
                                w * output_w_stride + co];

                // Initialize registers with zero if the first
                // tile is processed, otherwise load intermediate values
                if (flag_y_accumulate_start) {
                    for (uint32_t i = 0; i < max_unroll; i++) {
                        sum[i].f64 = 0.0;
                        reduce_reg[i] = 0.0;
                    }
                } else {
                    for (uint32_t i = 0; i < max_unroll; i++) {
                        sum[i].f64 = 0.0;
                        reduce_reg[i] = _pOutBuffer[i * output_h_stride];
                    }
                }

                // SSR address setup and enable
                snrt_ssr_read(
                    SNRT_SSR_DM0, SNRT_SSR_4D,
                    (void*)(pInBuffer +
                            h0 * max_unroll * stride_y * input_h_stride +
                            w * stride_x * input_w_stride));
                snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_3D,
                              (void*)(pWeight + co * kernel_co_stride));
                snrt_ssr_enable();

                asm volatile(
                    // frep over vfMACs
                    "frep.o %[n_frep], 8, 0, 0 \n"
                    "vfmac.s %[sum0], ft0, ft1 \n"
                    "vfmac.s %[sum1], ft0, ft1 \n"
                    "vfmac.s %[sum2], ft0, ft1 \n"
                    "vfmac.s %[sum3], ft0, ft1 \n"
                    "vfmac.s %[sum4], ft0, ft1 \n"
                    "vfmac.s %[sum5], ft0, ft1 \n"
                    "vfmac.s %[sum6], ft0, ft1 \n"
                    "vfmac.s %[sum7], ft0, ft1 \n"
                    // Sum reduce vector
                    "vfsum.s %[reduce_reg0], %[sum0] \n"
                    "vfsum.s %[reduce_reg1], %[sum1] \n"
                    "vfsum.s %[reduce_reg2], %[sum2] \n"
                    "vfsum.s %[reduce_reg3], %[sum3] \n"
                    "vfsum.s %[reduce_reg4], %[sum4] \n"
                    "vfsum.s %[reduce_reg5], %[sum5] \n"
                    "vfsum.s %[reduce_reg6], %[sum6] \n"
                    "vfsum.s %[reduce_reg7], %[sum7] \n"
                    : [sum0] "+f"(sum[0].f64), [sum1] "+f"(sum[1].f64),
                      [sum2] "+f"(sum[2].f64), [sum3] "+f"(sum[3].f64),
                      [sum4] "+f"(sum[4].f64), [sum5] "+f"(sum[5].f64),
                      [sum6] "+f"(sum[6].f64), [sum7] "+f"(sum[7].f64),
                      [reduce_reg0] "+f"(reduce_reg[0]),
                      [reduce_reg1] "+f"(reduce_reg[1]),
                      [reduce_reg2] "+f"(reduce_reg[2]),
                      [reduce_reg3] "+f"(reduce_reg[3]),
                      [reduce_reg4] "+f"(reduce_reg[4]),
                      [reduce_reg5] "+f"(reduce_reg[5]),
                      [reduce_reg6] "+f"(reduce_reg[6]),
                      [reduce_reg7] "+f"(reduce_reg[7])
                    : [n_frep] "r"(dim_kernel_y * dim_kernel_x * ch_in / 2 - 1)
                    : "ft0", "ft1", "ft2");

                snrt_ssr_disable();

                // Write back output values
                for (uint32_t i = 0; i < max_unroll; i++) {
                    _pOutBuffer[i * output_h_stride] = reduce_reg[i];
                }
            }
        }

        // Clean up rows
        if (cleanup_unroll) {
            // Modify most inner loop unrolling
            snrt_ssr_loop_4d(SNRT_SSR_DM0, cleanup_unroll, ssr0_b[1], ssr0_b[2],
                             ssr0_b[3], ssr0_i[0], ssr0_i[1], ssr0_i[2],
                             ssr0_i[3]);

            snrt_ssr_loop_3d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2],
                             ssr1_i[0], ssr1_i[1], ssr1_i[2]);

            snrt_ssr_repeat(SNRT_SSR_DM1, cleanup_unroll);

            // Output width dimension `dim_out_x`
            for (uint32_t w = 0; w < dim_out_x; w++) {
                register v2s sum[max_unroll];
                register float reduce_reg[max_unroll];

                // pointer to output buffer location where intermediate values
                // are read from and stored
                float* _pOutBuffer =
                    &pOutBuffer[(h0 * max_unroll) * output_h_stride +
                                w * output_w_stride + co];

                if (flag_y_accumulate_start) {
                    for (uint32_t i = 0; i < cleanup_unroll; i++) {
                        sum[i].f64 = 0.0;
                        reduce_reg[i] = 0.0;
                    }
                } else {
                    for (uint32_t i = 0; i < cleanup_unroll; i++) {
                        sum[i].f64 = 0.0;
                        reduce_reg[i] = _pOutBuffer[i * output_h_stride];
                    }
                }

                // SSR address setup and enable
                snrt_ssr_read(
                    SNRT_SSR_DM0, SNRT_SSR_4D,
                    (void*)(pInBuffer +
                            h0 * max_unroll * stride_y * input_h_stride +
                            w * stride_x * input_w_stride));
                snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_3D,
                              (void*)(pWeight + co * kernel_co_stride));
                snrt_ssr_enable();

                switch (cleanup_unroll) {
                    case 7:
                        asm volatile(
                            // frep over vfMACs
                            "frep.o %[n_frep], 7, 0, 0 \n"
                            "vfmac.s %[sum0], ft0, ft1 \n"
                            "vfmac.s %[sum1], ft0, ft1 \n"
                            "vfmac.s %[sum2], ft0, ft1 \n"
                            "vfmac.s %[sum3], ft0, ft1 \n"
                            "vfmac.s %[sum4], ft0, ft1 \n"
                            "vfmac.s %[sum5], ft0, ft1 \n"
                            "vfmac.s %[sum6], ft0, ft1 \n"
                            // Sum reduce vector
                            "vfsum.s %[reduce_reg0], %[sum0] \n"
                            "vfsum.s %[reduce_reg1], %[sum1] \n"
                            "vfsum.s %[reduce_reg2], %[sum2] \n"
                            "vfsum.s %[reduce_reg3], %[sum3] \n"
                            "vfsum.s %[reduce_reg4], %[sum4] \n"
                            "vfsum.s %[reduce_reg5], %[sum5] \n"
                            "vfsum.s %[reduce_reg6], %[sum6] \n"
                            : [sum0] "+f"(sum[0].f64), [sum1] "+f"(sum[1].f64),
                              [sum2] "+f"(sum[2].f64), [sum3] "+f"(sum[3].f64),
                              [sum4] "+f"(sum[4].f64), [sum5] "+f"(sum[5].f64),
                              [sum6] "+f"(sum[6].f64),
                              [reduce_reg0] "+f"(reduce_reg[0]),
                              [reduce_reg1] "+f"(reduce_reg[1]),
                              [reduce_reg2] "+f"(reduce_reg[2]),
                              [reduce_reg3] "+f"(reduce_reg[3]),
                              [reduce_reg4] "+f"(reduce_reg[4]),
                              [reduce_reg5] "+f"(reduce_reg[5]),
                              [reduce_reg6] "+f"(reduce_reg[6])
                            : [n_frep] "r"(
                                dim_kernel_y * dim_kernel_x * ch_in / 2 - 1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 6:
                        asm volatile(
                            // frep over vfMACs
                            "frep.o %[n_frep], 6, 0, 0 \n"
                            "vfmac.s %[sum0], ft0, ft1 \n"
                            "vfmac.s %[sum1], ft0, ft1 \n"
                            "vfmac.s %[sum2], ft0, ft1 \n"
                            "vfmac.s %[sum3], ft0, ft1 \n"
                            "vfmac.s %[sum4], ft0, ft1 \n"
                            "vfmac.s %[sum5], ft0, ft1 \n"
                            // Sum reduce vector
                            "vfsum.s %[reduce_reg0], %[sum0] \n"
                            "vfsum.s %[reduce_reg1], %[sum1] \n"
                            "vfsum.s %[reduce_reg2], %[sum2] \n"
                            "vfsum.s %[reduce_reg3], %[sum3] \n"
                            "vfsum.s %[reduce_reg4], %[sum4] \n"
                            "vfsum.s %[reduce_reg5], %[sum5] \n"
                            : [sum0] "+f"(sum[0].f64), [sum1] "+f"(sum[1].f64),
                              [sum2] "+f"(sum[2].f64), [sum3] "+f"(sum[3].f64),
                              [sum4] "+f"(sum[4].f64), [sum5] "+f"(sum[5].f64),
                              [reduce_reg0] "+f"(reduce_reg[0]),
                              [reduce_reg1] "+f"(reduce_reg[1]),
                              [reduce_reg2] "+f"(reduce_reg[2]),
                              [reduce_reg3] "+f"(reduce_reg[3]),
                              [reduce_reg4] "+f"(reduce_reg[4]),
                              [reduce_reg5] "+f"(reduce_reg[5])
                            : [n_frep] "r"(
                                dim_kernel_y * dim_kernel_x * ch_in / 2 - 1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 5:
                        asm volatile(
                            // frep over vfMACs
                            "frep.o %[n_frep], 5, 0, 0 \n"
                            "vfmac.s %[sum0], ft0, ft1 \n"
                            "vfmac.s %[sum1], ft0, ft1 \n"
                            "vfmac.s %[sum2], ft0, ft1 \n"
                            "vfmac.s %[sum3], ft0, ft1 \n"
                            "vfmac.s %[sum4], ft0, ft1 \n"
                            // Sum reduce vector
                            "vfsum.s %[reduce_reg0], %[sum0] \n"
                            "vfsum.s %[reduce_reg1], %[sum1] \n"
                            "vfsum.s %[reduce_reg2], %[sum2] \n"
                            "vfsum.s %[reduce_reg3], %[sum3] \n"
                            "vfsum.s %[reduce_reg4], %[sum4] \n"
                            : [sum0] "+f"(sum[0].f64), [sum1] "+f"(sum[1].f64),
                              [sum2] "+f"(sum[2].f64), [sum3] "+f"(sum[3].f64),
                              [sum4] "+f"(sum[4].f64),
                              [reduce_reg0] "+f"(reduce_reg[0]),
                              [reduce_reg1] "+f"(reduce_reg[1]),
                              [reduce_reg2] "+f"(reduce_reg[2]),
                              [reduce_reg3] "+f"(reduce_reg[3]),
                              [reduce_reg4] "+f"(reduce_reg[4])
                            : [n_frep] "r"(
                                dim_kernel_y * dim_kernel_x * ch_in / 2 - 1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 4:
                        asm volatile(
                            // frep over vfMACs
                            "frep.o %[n_frep], 4, 0, 0 \n"
                            "vfmac.s %[sum0], ft0, ft1 \n"
                            "vfmac.s %[sum1], ft0, ft1 \n"
                            "vfmac.s %[sum2], ft0, ft1 \n"
                            "vfmac.s %[sum3], ft0, ft1 \n"
                            // Sum reduce vector
                            "vfsum.s %[reduce_reg0], %[sum0] \n"
                            "vfsum.s %[reduce_reg1], %[sum1] \n"
                            "vfsum.s %[reduce_reg2], %[sum2] \n"
                            "vfsum.s %[reduce_reg3], %[sum3] \n"
                            : [sum0] "+f"(sum[0].f64), [sum1] "+f"(sum[1].f64),
                              [sum2] "+f"(sum[2].f64), [sum3] "+f"(sum[3].f64),
                              [reduce_reg0] "+f"(reduce_reg[0]),
                              [reduce_reg1] "+f"(reduce_reg[1]),
                              [reduce_reg2] "+f"(reduce_reg[2]),
                              [reduce_reg3] "+f"(reduce_reg[3])
                            : [n_frep] "r"(
                                dim_kernel_y * dim_kernel_x * ch_in / 2 - 1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 3:
                        asm volatile(
                            // frep over vfMACs
                            "frep.o %[n_frep], 3, 0, 0 \n"
                            "vfmac.s %[sum0], ft0, ft1 \n"
                            "vfmac.s %[sum1], ft0, ft1 \n"
                            "vfmac.s %[sum2], ft0, ft1 \n"
                            // Sum reduce vector
                            "vfsum.s %[reduce_reg0], %[sum0] \n"
                            "vfsum.s %[reduce_reg1], %[sum1] \n"
                            "vfsum.s %[reduce_reg2], %[sum2] \n"
                            : [sum0] "+f"(sum[0].f64), [sum1] "+f"(sum[1].f64),
                              [sum2] "+f"(sum[2].f64),
                              [reduce_reg0] "+f"(reduce_reg[0]),
                              [reduce_reg1] "+f"(reduce_reg[1]),
                              [reduce_reg2] "+f"(reduce_reg[2])
                            : [n_frep] "r"(
                                dim_kernel_y * dim_kernel_x * ch_in / 2 - 1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 2:
                        asm volatile(
                            // frep over vfMACs
                            "frep.o %[n_frep], 2, 0, 0 \n"
                            "vfmac.s %[sum0], ft0, ft1 \n"
                            "vfmac.s %[sum1], ft0, ft1 \n"
                            // Sum reduce vector
                            "vfsum.s %[reduce_reg0], %[sum0] \n"
                            "vfsum.s %[reduce_reg1], %[sum1] \n"
                            : [sum0] "+f"(sum[0].f64), [sum1] "+f"(sum[1].f64),
                              [reduce_reg0] "+f"(reduce_reg[0]),
                              [reduce_reg1] "+f"(reduce_reg[1])
                            : [n_frep] "r"(
                                dim_kernel_y * dim_kernel_x * ch_in / 2 - 1)
                            : "ft0", "ft1", "ft2");
                        break;
                    case 1:
                        asm volatile(
                            // frep over vfMACs
                            "frep.o %[n_frep], 2, 0, 0 \n"
                            "vfmac.s %[sum0], ft0, ft1 \n"
                            // Sum reduce vector
                            "vfsum.s %[reduce_reg0], %[sum0] \n"
                            : [sum0] "+f"(sum[0].f64), [reduce_reg0] "+f"(
                                                           reduce_reg[0])
                            : [n_frep] "r"(
                                dim_kernel_y * dim_kernel_x * ch_in / 2 - 1)
                            : "ft0", "ft1", "ft2");
                        break;
                }

                snrt_ssr_disable();

                for (uint32_t i = 0; i < cleanup_unroll; i++) {
                    _pOutBuffer[i * output_h_stride] = reduce_reg[i];
                }
            }
        }
    }

    // Cores need to be synchronized as the conv2d is parallized over output
    // channels but BatchNorm/ReLU uses the channel dimension for SIMD
    // instructions
    snrt_cluster_hw_barrier();

    if (flag_batch_norm | flag_relu) {
        // Refernce Loops
        // for (int co = 0; co < ch_out; co++) {
        //     for (int y = 0; y < dim_out_y; y++) {
        //         for (int x = 0; x < dim_out_x; x++) {
        //             pOutBuffer[y][x][co] =  max(pOutBuffer[y][x][co] * k[co]
        //             + l[co], 0);
        //         }
        //     }
        // }

        // Ouput channels are distributed across cores, SIMD operates on pairs
        // of 2 One SSR reads, while the other SSR writes back to the same
        // location
        snrt_ssr_loop_2d(SNRT_SSR_DM0, dim_out_x * dim_out_y,
                         ch_out / compute_num / 2, sizeof(float) * ch_out,
                         sizeof(v2s));
        snrt_ssr_loop_2d(SNRT_SSR_DM1, dim_out_x * dim_out_y,
                         ch_out / compute_num / 2, sizeof(float) * ch_out,
                         sizeof(v2s));
        snrt_ssr_repeat(SNRT_SSR_DM1, 1);  // Disable repeat from conv2d

        snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_2D, &pOutBuffer[compute_id * 2]);
        snrt_ssr_write(SNRT_SSR_DM1, SNRT_SSR_2D, &pOutBuffer[compute_id * 2]);

        snrt_ssr_enable();

        for (uint32_t co = compute_id; co < ch_out / 2; co += compute_num) {
            register v2s current_lambda = ((v2s*)lambda)[co];
            register v2s current_k = ((v2s*)k)[co];
            register v2s zero = (v2s)0.0;

            register v2s tmp;

            // TODO: unroll to solve RAW dependencies
            if (flag_batch_norm && flag_relu) {
                asm volatile(
                    "frep.o %[n_frep], 3, 0, 0\n"
                    "vfmul.s %[tmp], ft0, %[k]\n"     // BN kappa
                    "vfadd.s %[tmp], %[tmp], %[l]\n"  // BN lambda
                    "vfmax.s ft1, %[tmp], %[zero]\n"  // ReLU
                    : [tmp] "+f"(tmp.f64)
                    : [k] "f"(current_k.f64), [l] "f"(current_lambda.f64),
                      [zero] "f"(zero.f64),
                      [n_frep] "r"(dim_out_x * dim_out_y - 1)
                    : "ft0", "ft1", "ft2");
            } else if (flag_batch_norm && !flag_relu) {
                asm volatile(
                    "frep.o %[n_frep], 2, 0, 0\n"
                    "vfmul.s %[tmp], ft0, %[k]\n"  // BN kappa
                    "vfadd.s ft1, %[tmp], %[l]\n"  // BN lambda
                    : [tmp] "+f"(tmp.f64), [k] "+f"(current_k.f64),
                      [l] "+f"(current_lambda.f64)
                    : [n_frep] "r"(dim_out_x * dim_out_y - 1)
                    : "ft0", "ft1", "ft2");
            } else if (!flag_batch_norm && flag_relu) {
                asm volatile(
                    "frep.o %[n_frep], 1, 0, 0 \n"
                    "vfmax.s ft1, ft0, %[zero]\n"  // ReLU
                    ::[zero] "f"(zero.f64),
                    [n_frep] "r"(dim_out_x * dim_out_y - 1)
                    : "ft0", "ft1", "ft2");
            }
        }

        snrt_ssr_disable();
    }
}
