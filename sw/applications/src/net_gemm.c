// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// SW testbench for profiling GEMM kernels in different
// floating point precisions (fp64, fp32, fp16), as well as
// different memory layouts for matrices (transposed/not-transposed)
// Correctness of results are checked automatically

#include "data_gemm.h"
#include "gemm.h"
#include "layer.h"
#include "math.h"
#include "perf_cnt.h"
#include "printf.h"
#include "snrt.h"
#include "utils.h"

// Padding of innermost dimension of a Matrix
// Useful for preventing banking conflicts between cores
// that are accessing different rows of the matrix
#define MAT_ROW_PADDING 0

// Padding in between matrices A, B for preventing
// banking conflicts in the beginning
#define MAT_PADDING 0

void *share_ptr;

int main() {
    gemm_l.A = (void *)gemm_A_dram;
    gemm_l.B = (void *)gemm_B_dram;
    gemm_l.C = (void *)gemm_C_dram;

    const gemm_layer l1_gemm_l = gemm_l;

    const uint32_t cluster_num = snrt_cluster_num();
    const uint32_t cluster_id = snrt_cluster_idx();
    const uint32_t compute_num = snrt_cluster_compute_core_num();
    const uint32_t compute_id = snrt_cluster_compute_core_idx();

    void *mat_A, *mat_B, *mat_C;

    uint32_t mat_A_size =
        (l1_gemm_l.M * (l1_gemm_l.K + MAT_ROW_PADDING) + MAT_PADDING) *
        l1_gemm_l.dtype;
    uint32_t mat_B_size =
        (l1_gemm_l.K + MAT_ROW_PADDING) * l1_gemm_l.N * l1_gemm_l.dtype;
    uint32_t mat_C_size = l1_gemm_l.M * l1_gemm_l.N * l1_gemm_l.dtype;

    uint32_t total_size = mat_A_size + mat_B_size + mat_C_size;

    void *ptr;

    if (compute_id == 0) {
        ptr = snrt_l1alloc(total_size);
        share_ptr = ptr;
    }

    snrt_cluster_hw_barrier();

    ptr = share_ptr;

    mat_A = ptr;
    ptr += (l1_gemm_l.M * (l1_gemm_l.K + MAT_ROW_PADDING) + MAT_PADDING) *
           l1_gemm_l.dtype;
    mat_B = ptr;
    ptr += (l1_gemm_l.K + MAT_ROW_PADDING) * l1_gemm_l.N * l1_gemm_l.dtype;
    mat_C = ptr;
    ptr += l1_gemm_l.M * l1_gemm_l.N * l1_gemm_l.dtype;

    uint32_t errors = 0;

    snrt_global_barrier();

    if (snrt_is_dm_core()) {
        snrt_dma_txid_t txid_A =
            snrt_dma_start_2d(mat_A, l1_gemm_l.A, l1_gemm_l.dtype * l1_gemm_l.K,
                              l1_gemm_l.dtype * (l1_gemm_l.K + MAT_ROW_PADDING),
                              l1_gemm_l.dtype * l1_gemm_l.K, l1_gemm_l.M);
        snrt_dma_txid_t txid_B =
            snrt_dma_start_2d(mat_B, l1_gemm_l.B, l1_gemm_l.dtype * l1_gemm_l.K,
                              l1_gemm_l.dtype * (l1_gemm_l.K + MAT_ROW_PADDING),
                              l1_gemm_l.dtype * l1_gemm_l.K, l1_gemm_l.N);

        snrt_dma_txid_t txid_C = snrt_dma_start_1d(
            mat_C, l1_gemm_l.C, l1_gemm_l.dtype * l1_gemm_l.M * l1_gemm_l.N);

        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    if (snrt_is_compute_core() &&
        snrt_cluster_compute_core_idx() < compute_num) {
        const uint32_t setup_SSR = 1;

        if (!l1_gemm_l.TA && !l1_gemm_l.TB) {
            volatile uint32_t A_offset =
                compute_id * (l1_gemm_l.K + MAT_ROW_PADDING) * l1_gemm_l.dtype;
            volatile uint32_t C_offset =
                compute_id * l1_gemm_l.N * l1_gemm_l.dtype;
            volatile uint32_t ldA =
                compute_num * (l1_gemm_l.K + MAT_ROW_PADDING);
            volatile uint32_t ldB = l1_gemm_l.K + MAT_ROW_PADDING;
            volatile uint32_t ldC = l1_gemm_l.N * compute_num;

            benchmark_get_cycle();
            gemm_fp64_ssr_frep(l1_gemm_l.M / compute_num, l1_gemm_l.N,
                               l1_gemm_l.K, &mat_A[A_offset], ldA, l1_gemm_l.TA,
                               mat_B, ldB, l1_gemm_l.TB, &mat_C[C_offset], ldC,
                               &l1_gemm_l.ALPHA, setup_SSR);
            benchmark_get_cycle();
        } else if (!l1_gemm_l.TA && l1_gemm_l.TB) {
            volatile uint32_t A_offset =
                compute_id * (l1_gemm_l.K + MAT_ROW_PADDING) * l1_gemm_l.dtype;
            volatile uint32_t C_offset =
                compute_id * l1_gemm_l.N * l1_gemm_l.dtype;
            volatile uint32_t ldA =
                compute_num * (l1_gemm_l.K + MAT_ROW_PADDING);
            volatile uint32_t ldB = l1_gemm_l.K + MAT_ROW_PADDING;
            volatile uint32_t ldC = l1_gemm_l.N * compute_num;

            benchmark_get_cycle();
            switch (l1_gemm_l.dtype) {
                case FP64:
                    gemm_fp64_ssr_frep(l1_gemm_l.M / compute_num, l1_gemm_l.N,
                                       l1_gemm_l.K, &mat_A[A_offset], ldA,
                                       l1_gemm_l.TA, mat_B, ldB, l1_gemm_l.TB,
                                       &mat_C[C_offset], ldC, &l1_gemm_l.ALPHA,
                                       setup_SSR);
                    break;
                case FP32:
                    gemm_fp32simd_tb_ssr_frep(
                        l1_gemm_l.M / compute_num, l1_gemm_l.N, l1_gemm_l.K,
                        &mat_A[A_offset], ldA, mat_B, ldB, &mat_C[C_offset],
                        ldC, &l1_gemm_l.ALPHA, setup_SSR);
                    break;
                case FP16:
                    gemm_fp16simd_tb_ssr_frep(
                        l1_gemm_l.M / compute_num, l1_gemm_l.N, l1_gemm_l.K,
                        &mat_A[A_offset], ldA, mat_B, ldB, &mat_C[C_offset],
                        ldC, &l1_gemm_l.ALPHA, setup_SSR);
                    break;
                case FP8:
                    gemm_fp8simd_tb_ssr_frep(
                        l1_gemm_l.M / compute_num, l1_gemm_l.N, l1_gemm_l.K,
                        &mat_A[A_offset], ldA, mat_B, ldB, &mat_C[C_offset],
                        ldC, &l1_gemm_l.ALPHA, setup_SSR);
                    break;
            }
            benchmark_get_cycle();
        } else if (l1_gemm_l.TA && !l1_gemm_l.TB) {
            volatile uint32_t A_offset = compute_id * l1_gemm_l.dtype;
            volatile uint32_t C_offset =
                compute_id * l1_gemm_l.N * l1_gemm_l.dtype;
            volatile uint32_t ldA = (l1_gemm_l.K + MAT_ROW_PADDING);
            volatile uint32_t ldB = l1_gemm_l.K + MAT_ROW_PADDING;
            volatile uint32_t ldC = l1_gemm_l.N * compute_num;

            benchmark_get_cycle();
            gemm_fp64_ssr_frep(l1_gemm_l.M / compute_num, l1_gemm_l.N,
                               l1_gemm_l.K, &mat_A[A_offset], ldA, l1_gemm_l.TA,
                               mat_B, ldB, l1_gemm_l.TB, &mat_C[C_offset], ldC,
                               &l1_gemm_l.ALPHA, setup_SSR);
            benchmark_get_cycle();
        } else if (l1_gemm_l.TA && l1_gemm_l.TB) {
            volatile uint32_t A_offset = compute_id * l1_gemm_l.dtype;
            volatile uint32_t C_offset =
                compute_id * l1_gemm_l.N * l1_gemm_l.dtype;
            volatile uint32_t ldA = (l1_gemm_l.K + MAT_ROW_PADDING);
            volatile uint32_t ldB = l1_gemm_l.K + MAT_ROW_PADDING;
            volatile uint32_t ldC = l1_gemm_l.N * compute_num;

            benchmark_get_cycle();
            gemm_fp64_ssr_frep(l1_gemm_l.M / compute_num, l1_gemm_l.N,
                               l1_gemm_l.K, &mat_A[A_offset], ldA, l1_gemm_l.TA,
                               mat_B, ldB, l1_gemm_l.TB, &mat_C[C_offset], ldC,
                               &l1_gemm_l.ALPHA, setup_SSR);
            benchmark_get_cycle();
        }
        snrt_cluster_hw_barrier();
    } else {
        snrt_cluster_hw_barrier();
    }
    snrt_cluster_hw_barrier();

    if (compute_id == 0) {
        if (l1_gemm_l.dtype == FP64) {
            for (uint32_t m = 0; m < l1_gemm_l.M; m++) {
                double checksum = gemm_checksum[m];
                double sum = 0.0;
                for (uint32_t n = 0; n < l1_gemm_l.N; n++) {
                    sum += ((double *)mat_C)[m * l1_gemm_l.N + n];
                }
                if (fabs(sum - checksum) > 0.001) {
                    errors++;
                }
            }
        } else if (l1_gemm_l.dtype == FP32) {
            for (uint32_t m = 0; m < l1_gemm_l.M; m++) {
                float checksum = gemm_checksum[m];
                float sum = 0.0;
                for (uint32_t n = 0; n < l1_gemm_l.N; n++) {
                    sum += ((float *)mat_C)[m * l1_gemm_l.N + n];
                }
                if (fabs(sum - checksum) > 0.001) {
                    errors++;
                }
            }
        } else if (l1_gemm_l.dtype == FP16) {
            for (uint32_t m = 0; m < l1_gemm_l.M; m++) {
                __fp16 checksum = gemm_checksum[m];
                float sum = 0.0;
                for (uint32_t n = 0; n < l1_gemm_l.N; n++) {
                    sum += ((__fp16 *)mat_C)[m * l1_gemm_l.N + n];
                }
                if (fabs(sum - checksum) > 0.05) {
                    errors++;
                }
            }
        } else if (l1_gemm_l.dtype == FP8) {
            printf("No golden model yet for fp8!\n");
        }
        printf("%d/%d Errors\n", errors, l1_gemm_l.M * l1_gemm_l.N);
    }

    return 0;
}
