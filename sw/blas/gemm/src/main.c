// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

#include <math.h>
#include <stdint.h>

#include "data.h"
#include "gemm.h"
#include "snrt.h"

// Padding of innermost dimension of a Matrix
// Useful for preventing banking conflicts between cores
// that are accessing different rows of the matrix
#define MAT_ROW_PADDING 0

// Padding in between matrices A, B for preventing
// banking conflicts in the beginning
#define MAT_PADDING 0

#define CHECK_RESULT

typedef enum { FP64 = 8, FP32 = 4, FP16 = 2, FP8 = 1 } precision_t;

void *l1_a, *l1_b, *l1_c;

int main() {
    const uint32_t compute_num = snrt_cluster_compute_core_num();
    const uint32_t compute_id = snrt_cluster_core_idx();

    uint32_t a_size = (M * (K + MAT_ROW_PADDING) + MAT_PADDING) * dtype_size;
    uint32_t b_size = (K + MAT_ROW_PADDING) * N * dtype_size;
    uint32_t c_size = M * N * dtype_size;

    if (snrt_is_dm_core()) {
        l1_a = snrt_l1alloc(a_size);
        l1_b = snrt_l1alloc(b_size);
        l1_c = snrt_l1alloc(c_size);
        snrt_dma_start_2d(l1_a, a, dtype_size * K,
                          dtype_size * (K + MAT_ROW_PADDING), dtype_size * K,
                          M);
        snrt_dma_start_2d(l1_b, b, dtype_size * K,
                          dtype_size * (K + MAT_ROW_PADDING), dtype_size * K,
                          N);
        snrt_dma_start_1d(l1_c, c, dtype_size * M * N);
        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    // Compute
    if (!snrt_is_dm_core()) {
        const uint32_t setup_SSR = 1;
        uint32_t start_cycle = mcycle();

        if (!TA && !TB) {
            volatile uint32_t A_offset =
                compute_id * (K + MAT_ROW_PADDING) * dtype_size;
            volatile uint32_t C_offset = compute_id * N * dtype_size;
            volatile uint32_t ldA = compute_num * (K + MAT_ROW_PADDING);
            volatile uint32_t ldB = N + MAT_ROW_PADDING;
            volatile uint32_t ldC = N * compute_num;

            gemm_fp64_opt(M / compute_num, N, K, &l1_a[A_offset], ldA, TA, l1_b,
                          ldB, TB, &l1_c[C_offset], ldC, &ALPHA, setup_SSR);
        } else if (!TA && TB) {
            volatile uint32_t A_offset =
                compute_id * (K + MAT_ROW_PADDING) * dtype_size;
            volatile uint32_t C_offset = compute_id * N * dtype_size;
            volatile uint32_t ldA = compute_num * (K + MAT_ROW_PADDING);
            volatile uint32_t ldB = K + MAT_ROW_PADDING;
            volatile uint32_t ldC = N * compute_num;

            switch (dtype_size) {
                case FP64:
                    gemm_fp64_opt(M / compute_num, N, K, &l1_a[A_offset], ldA,
                                  TA, l1_b, ldB, TB, &l1_c[C_offset], ldC,
                                  &ALPHA, setup_SSR);
                    break;
                case FP32:
                    gemm_fp32_opt(M / compute_num, N, K, &l1_a[A_offset], ldA,
                                  l1_b, ldB, &l1_c[C_offset], ldC, &ALPHA,
                                  setup_SSR);
                    break;
                case FP16:
                    if (expand) {
                        gemm_fp16_ex_opt(M / compute_num, N, K, &l1_a[A_offset],
                                         ldA, l1_b, ldB, &l1_c[C_offset], ldC,
                                         &ALPHA, setup_SSR);
                    } else {
                        gemm_fp16_opt(M / compute_num, N, K, &l1_a[A_offset],
                                      ldA, l1_b, ldB, &l1_c[C_offset], ldC,
                                      &ALPHA, setup_SSR);
                    }
                    break;
                case FP8:
                    gemm_fp8_ex_opt(M / compute_num, N, K, &l1_a[A_offset], ldA,
                                    l1_b, ldB, &l1_c[C_offset], ldC, &ALPHA,
                                    setup_SSR);
                    break;
            }
        } else if (TA) {
            printf("transpose TA not supported\n");
        }
        uint32_t end_cycle = mcycle();
    }

    snrt_cluster_hw_barrier();

#ifdef CHECK_RESULT

    uint32_t errors = 0;
    if (compute_id == 0) {
        switch (dtype_size) {
            case FP64:
                for (uint32_t m = 0; m < M; m++) {
                    for (uint32_t n = 0; n < N; n++) {
                        uint32_t idx = m * N + n;
                        if (fabs(result[idx] - ((double *)l1_c)[idx]) > 0.001)
                            errors++;
                    }
                }
                break;
            case FP32:
                for (uint32_t m = 0; m < M; m++) {
                    for (uint32_t n = 0; n < N; n++) {
                        uint32_t idx = m * N + n;
                        if (fabs(result[idx] - ((float *)l1_c)[idx]) > 0.001)
                            errors++;
                    }
                }
                break;
            case FP16:
                for (uint32_t m = 0; m < M; m++) {
                    for (uint32_t n = 0; n < N; n++) {
                        uint32_t idx = m * N + n;
                        if (fabs(result[idx] - ((__fp16 *)l1_c)[idx]) > 0.001)
                            errors++;
                    }
                }
                break;
            case FP8:
                printf("No golden model yet for fp8!\n");
                return -1;
                break;
        }
        printf("%d/%d Errors\n", errors, M * N);
    }
    return errors;

#endif

    return 0;
}
