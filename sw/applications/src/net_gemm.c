// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "layer.h"
#include "data_gemm.h"
#include "gemm.h"
#include "utils.h"
#include "snrt.h"
#include "printf.h"
#include "perf_cnt.h"
#include "math.h"

#define MAT_ROW_PADDING 4
#define MAT_PADDING 8

int main() {


    gemm_l.A = (void *)gemm_A_dram;
    gemm_l.B = (void *)gemm_B_dram;
    gemm_l.C = (void *)gemm_C_dram;

    const layer l1_gemm_l = gemm_l;

    volatile uint32_t cluster_num = snrt_cluster_num();
    volatile uint32_t cluster_id = snrt_cluster_idx();
    volatile uint32_t compute_num = snrt_cluster_compute_core_num();
    volatile uint32_t compute_id = snrt_cluster_compute_core_idx();

    void *mat_A, *mat_B, *mat_C;
    void *ptr = (double*)snrt_cluster_memory().start;

    mat_A = ptr;
    ptr += (l1_gemm_l.M * (l1_gemm_l.K + MAT_ROW_PADDING) + MAT_PADDING) * l1_gemm_l.dtype;
    mat_B = ptr;
    ptr += (l1_gemm_l.K + MAT_ROW_PADDING) * l1_gemm_l.N * l1_gemm_l.dtype;
    mat_C = ptr;
    ptr += l1_gemm_l.M * l1_gemm_l.N * l1_gemm_l.dtype;


    uint32_t errors = 0;

    snrt_global_barrier();

    if (snrt_is_dm_core()) {
        snrt_dma_txid_t txid_A = \
            snrt_dma_start_2d(mat_A,
                            l1_gemm_l.A,
                            l1_gemm_l.dtype*l1_gemm_l.K,
                            l1_gemm_l.dtype*(l1_gemm_l.K + MAT_ROW_PADDING),
                            l1_gemm_l.dtype*l1_gemm_l.K,
                            l1_gemm_l.M);
        snrt_dma_txid_t txid_B = \
            snrt_dma_start_2d(mat_B,
                            l1_gemm_l.B,
                            l1_gemm_l.dtype*l1_gemm_l.K,
                            l1_gemm_l.dtype*(l1_gemm_l.K + MAT_ROW_PADDING),
                            l1_gemm_l.dtype*l1_gemm_l.K,
                            l1_gemm_l.N);

        snrt_dma_txid_t txid_C = \
            snrt_dma_start_1d(mat_C, l1_gemm_l.C, l1_gemm_l.dtype*l1_gemm_l.M*l1_gemm_l.N);

        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    if (snrt_is_compute_core() && snrt_cluster_compute_core_idx() < compute_num) {
        const uint32_t setup_SSR = 1;

        if (!l1_gemm_l.TA && !l1_gemm_l.TB) {
            volatile uint32_t A_offset = compute_id * (l1_gemm_l.K + MAT_ROW_PADDING) * l1_gemm_l.dtype;
            volatile uint32_t C_offset = compute_id * l1_gemm_l.N * l1_gemm_l.dtype;
            volatile uint32_t ldA = compute_num * (l1_gemm_l.K + MAT_ROW_PADDING);
            volatile uint32_t ldB = l1_gemm_l.K + MAT_ROW_PADDING;
            volatile uint32_t ldC = l1_gemm_l.N * compute_num;

            benchmark_get_cycle();
            gemm_fp64_ssr_frep(l1_gemm_l.M/compute_num, l1_gemm_l.N, l1_gemm_l.K,
                          &mat_A[A_offset], ldA, l1_gemm_l.TA,
                          mat_B, ldB, l1_gemm_l.TB,
                          &mat_C[C_offset], ldC,
                          &l1_gemm_l.ALPHA, setup_SSR);
            benchmark_get_cycle();
        }
        else if (!l1_gemm_l.TA && l1_gemm_l.TB) {
            volatile uint32_t A_offset = compute_id * (l1_gemm_l.K + MAT_ROW_PADDING) * l1_gemm_l.dtype;
            volatile uint32_t C_offset = compute_id * l1_gemm_l.N * l1_gemm_l.dtype;
            volatile uint32_t ldA = compute_num * (l1_gemm_l.K + MAT_ROW_PADDING);
            volatile uint32_t ldB = l1_gemm_l.K + MAT_ROW_PADDING;
            volatile uint32_t ldC = l1_gemm_l.N * compute_num;

            benchmark_get_cycle();
            if (l1_gemm_l.dtype == FP64) {
                gemm_fp64_ssr_frep(l1_gemm_l.M/compute_num, l1_gemm_l.N, l1_gemm_l.K,
                          &mat_A[A_offset], ldA, l1_gemm_l.TA,
                          mat_B, ldB, l1_gemm_l.TB,
                          &mat_C[C_offset], ldC,
                          &l1_gemm_l.ALPHA, setup_SSR);
            } else if (l1_gemm_l.dtype == FP32) {
                gemm_fp32simd_tb_ssr_frep(l1_gemm_l.M/compute_num, l1_gemm_l.N, l1_gemm_l.K,
                          &mat_A[A_offset], ldA,
                          mat_B, ldB,
                          &mat_C[C_offset], ldC,
                          &l1_gemm_l.ALPHA, setup_SSR);
            } else if (l1_gemm_l.dtype == FP16) {
                gemm_fp16simd_tb_ssr_frep(l1_gemm_l.M/compute_num, l1_gemm_l.N, l1_gemm_l.K,
                          &mat_A[A_offset], ldA,
                          mat_B, ldB,
                          &mat_C[C_offset], ldC,
                          &l1_gemm_l.ALPHA, setup_SSR);
            }
            benchmark_get_cycle();
        }
        else if (l1_gemm_l.TA && !l1_gemm_l.TB) {
            volatile uint32_t A_offset = compute_id * l1_gemm_l.dtype;
            volatile uint32_t C_offset = compute_id * l1_gemm_l.N * l1_gemm_l.dtype;
            volatile uint32_t ldA = (l1_gemm_l.K + MAT_ROW_PADDING);
            volatile uint32_t ldB = l1_gemm_l.K + MAT_ROW_PADDING;
            volatile uint32_t ldC = l1_gemm_l.N * compute_num;

            benchmark_get_cycle();
            gemm_fp64_ssr_frep(l1_gemm_l.M/compute_num, l1_gemm_l.N, l1_gemm_l.K,
                          &mat_A[A_offset], ldA, l1_gemm_l.TA,
                          mat_B, ldB, l1_gemm_l.TB,
                          &mat_C[C_offset], ldC,
                          &l1_gemm_l.ALPHA, setup_SSR);
            benchmark_get_cycle();
        }
        else if (l1_gemm_l.TA && l1_gemm_l.TB) {
            volatile uint32_t A_offset = compute_id * l1_gemm_l.dtype;
            volatile uint32_t C_offset = compute_id * l1_gemm_l.N * l1_gemm_l.dtype;
            volatile uint32_t ldA = (l1_gemm_l.K + MAT_ROW_PADDING);
            volatile uint32_t ldB = l1_gemm_l.K + MAT_ROW_PADDING;
            volatile uint32_t ldC = l1_gemm_l.N * compute_num;

            benchmark_get_cycle();
            gemm_fp64_ssr_frep(l1_gemm_l.M/compute_num, l1_gemm_l.N, l1_gemm_l.K,
                          &mat_A[A_offset], ldA, l1_gemm_l.TA,
                          mat_B, ldB, l1_gemm_l.TB,
                          &mat_C[C_offset], ldC,
                          &l1_gemm_l.ALPHA, setup_SSR);
            benchmark_get_cycle();
        }
        snrt_cluster_hw_barrier();
    }
    else {
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
        }
        else if (l1_gemm_l.dtype == FP32) {
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
        }
        else if (l1_gemm_l.dtype == FP16) {
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
        }
    }

    return errors;
}
