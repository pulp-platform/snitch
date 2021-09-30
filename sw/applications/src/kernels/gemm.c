// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "gemm.h"

#include "printf.h"
#include "snrt.h"

typedef float v2f32 __attribute__((vector_size(8)));
typedef __fp16 v4f16 __attribute__((vector_size(8)));
typedef char v8f8 __attribute__((vector_size(8)));

/**
 * @brief naive implementation of a FP64 GEMM
 *
 * @param M number of rows of matrix A
 * @param N number of columns of matrix B
 * @param K number of columns of matrix A
 * @param A pointer to matrix A
 * @param ldA row stride in matrix A
 * @param ta transposed memory layout for matrix A
 * @param B pointer to matrix B
 * @param ldB row stride in matrix B
 * @param tb transposed memory layout for matrix B
 * @param C pointer to matrix C
 * @param ldC row stride in matrix C
 * @param ALPHA accmulate factor of C
 */
void gemm_fp64(uint32_t M, uint32_t N, uint32_t K, double* A, uint32_t ldA,
               uint32_t ta, double* B, uint32_t ldB, uint32_t tb, double* C,
               uint32_t ldC, double ALPHA) {
    if (!ta && !tb) {
        for (uint32_t m = 0; m < M; m++) {
            for (uint32_t n = 0; n < N; n++) {
                register double c0 = ALPHA * C[m * ldC + n];
                for (uint32_t k = 0; k < K; k++) {
                    c0 += A[k + m * ldA] * B[k * ldB + n];
                }
                C[m * ldC + n] = c0;
            }
        }
    } else if (ta && !tb) {
        for (uint32_t m = 0; m < M; m++) {
            for (uint32_t n = 0; n < N; n++) {
                register double c0 = ALPHA * C[m * ldC + n];
                for (uint32_t k = 0; k < K; k++) {
                    c0 += A[k * M * ldA + m * ldA] * B[k * ldB + n];
                }
                C[m * ldC + n] = c0;
            }
        }
    } else if (!ta && tb) {
        for (uint32_t m = 0; m < M; m++) {
            for (uint32_t n = 0; n < N; n++) {
                register double c0 = ALPHA * C[m * ldC + n];
                for (uint32_t k = 0; k < K; k++) {
                    c0 += A[k + m * ldA] * B[k + n * ldB];
                }
                C[m * ldC + n] = c0;
            }
        }
    } else {
        for (uint32_t m = 0; m < M; m++) {
            for (uint32_t n = 0; n < N; n++) {
                register double c0 = ALPHA * C[m * ldC + n];
                for (uint32_t k = 0; k < K; k++) {
                    c0 += A[k * M * ldA + m * ldA] * B[k + n * ldB];
                }
                C[m * ldC + n] = c0;
            }
        }
    }
}

/**
 * @brief implementation of a FP64 GEMM with configured
 * SSRs and frep loop.
 *
 * @param M number of rows of matrix A
 * @param N number of columns of matrix B
 * @param K number of columns of matrix A
 * @param A pointer to matrix A
 * @param ldA row stride in matrix A
 * @param ta transposed memory layout for matrix A
 * @param B pointer to matrix B
 * @param ldB row stride in matrix B
 * @param tb transposed memory layout for matrix B
 * @param C pointer to matrix C
 * @param ldC row stride in matrix C
 * @param ALPHA accmulate factor of C
 * @param setup_SSR setup SSR bounds and strides
 */
void gemm_fp64_ssr_frep(uint32_t M, uint32_t N, uint32_t K, double* A,
                        uint32_t ldA, uint32_t ta, double* B, uint32_t ldB,
                        uint32_t tb, double* C, uint32_t ldC,
                        const uint32_t* ALPHA, uint32_t setup_SSR) {
    register volatile double ft0 asm("ft0");
    register volatile double ft1 asm("ft1");
    register volatile double ft2 asm("ft2");
    asm volatile("" : "=f"(ft0), "=f"(ft1), "=f"(ft2));

    // Unrolling factor of most inner loop.
    // Should be at least as high as the FMA delay
    // for maximum utilization
    const uint32_t unroll = 8;

    // SSR strides and bounds only have to be configured
    // once in the beginning
    if (setup_SSR) {
        // First matrix is stored in transposed format
        if (ta) {
            const uint32_t ssr0_b[4] = {unroll, K, N / unroll, M};
            const uint32_t ssr0_i[4] = {0, 8 * ldA, 0, 8 * 8};

            snrt_ssr_loop_3d(SNRT_SSR_DM0, ssr0_b[1], ssr0_b[2], ssr0_b[3],
                             ssr0_i[1], ssr0_i[2], ssr0_i[3]);
            snrt_ssr_repeat(SNRT_SSR_DM0, unroll);
        } else {
            const uint32_t ssr0_b[4] = {unroll, K, N / unroll, M};
            const uint32_t ssr0_i[4] = {0, 8, 0, 8 * ldA};

            snrt_ssr_loop_3d(SNRT_SSR_DM0, ssr0_b[1], ssr0_b[2], ssr0_b[3],
                             ssr0_i[1], ssr0_i[2], ssr0_i[3]);
            snrt_ssr_repeat(SNRT_SSR_DM0, unroll);
        }

        // Second matrix is stored in transposed format
        if (tb) {
            const uint32_t ssr1_b[4] = {unroll, K, N / unroll, M};
            const uint32_t ssr1_i[4] = {8 * ldB, 8, 8 * ldB * unroll, 0};

            snrt_ssr_loop_4d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2],
                             ssr1_b[3], ssr1_i[0], ssr1_i[1], ssr1_i[2],
                             ssr1_i[3]);
        } else {
            const uint32_t ssr1_b[4] = {unroll, K, N / unroll, M};
            const uint32_t ssr1_i[4] = {8, 8 * ldB, 8 * unroll, 0};

            snrt_ssr_loop_4d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2],
                             ssr1_b[3], ssr1_i[0], ssr1_i[1], ssr1_i[2],
                             ssr1_i[3]);
        }
    }

    // SSR start address need to be configured each time
    snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_4D, A);
    snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_4D, B);
    snrt_ssr_enable();

    for (uint32_t m = 0; m < M; m++) {
        uint32_t n = 0;
        for (uint32_t n0 = 0; n0 < N / unroll; n0++) {
            register double c[unroll];

            // Load intermediate result
            if (*ALPHA) {
                c[0] = C[m * ldC + n + 0];
                c[1] = C[m * ldC + n + 1];
                c[2] = C[m * ldC + n + 2];
                c[3] = C[m * ldC + n + 3];
                c[4] = C[m * ldC + n + 4];
                c[5] = C[m * ldC + n + 5];
                c[6] = C[m * ldC + n + 6];
                c[7] = C[m * ldC + n + 7];
            } else {
                c[0] = 0.0;
                c[1] = 0.0;
                c[2] = 0.0;
                c[3] = 0.0;
                c[4] = 0.0;
                c[5] = 0.0;
                c[6] = 0.0;
                c[7] = 0.0;
            }

            asm volatile(
                "frep.o %[n_frep], 8, 0, 0 \n"
                "fmadd.d %[c0], ft0, ft1, %[c0] \n"
                "fmadd.d %[c1], ft0, ft1, %[c1] \n"
                "fmadd.d %[c2], ft0, ft1, %[c2] \n"
                "fmadd.d %[c3], ft0, ft1, %[c3] \n"
                "fmadd.d %[c4], ft0, ft1, %[c4] \n"
                "fmadd.d %[c5], ft0, ft1, %[c5] \n"
                "fmadd.d %[c6], ft0, ft1, %[c6] \n"
                "fmadd.d %[c7], ft0, ft1, %[c7] \n"
                : [ c0 ] "+f"(c[0]), [ c1 ] "+f"(c[1]), [ c2 ] "+f"(c[2]),
                  [ c3 ] "+f"(c[3]), [ c4 ] "+f"(c[4]), [ c5 ] "+f"(c[5]),
                  [ c6 ] "+f"(c[6]), [ c7 ] "+f"(c[7])
                : [ n_frep ] "r"(K - 1)
                : "ft0", "ft1");

            // Store results back
            C[m * ldC + n + 0] = c[0];
            C[m * ldC + n + 1] = c[1];
            C[m * ldC + n + 2] = c[2];
            C[m * ldC + n + 3] = c[3];
            C[m * ldC + n + 4] = c[4];
            C[m * ldC + n + 5] = c[5];
            C[m * ldC + n + 6] = c[6];
            C[m * ldC + n + 7] = c[7];
            n += unroll;
        }

        // Clean up of leftover columns
        snrt_ssr_disable();

        for (; n < N; n++) {
            double c;
            if (*ALPHA) {
                c = C[m * ldC + n];
            } else {
                c = 0.0;
            }
            for (uint32_t k = 0; k < K; k++) {
                c += A[k + m * ldA] * B[k + n * ldB];
            }
            C[m * ldC + n] = c;
        }

        snrt_ssr_enable();
    }

    snrt_ssr_disable();

    asm volatile("" ::"f"(ft0), "f"(ft1), "f"(ft2));
}

/**
 * @brief implementation of a FP32 SIMD GEMM with configured
 * SSRs and frep loop. Matrix B has to be stored in transposed/consecutive
 * memory layout in order to support SIMD instructions.
 *
 * @param M number of rows of matrix A
 * @param N number of columns of matrix B
 * @param K number of columns of matrix A
 * @param A pointer to matrix A
 * @param ldA row stride in matrix A
 * @param ta transposed memory layout for matrix A
 * @param B pointer to matrix B
 * @param ldB row stride in matrix B
 * @param tb transposed memory layout for matrix B
 * @param C pointer to matrix C
 * @param ldC row stride in matrix C
 * @param ALPHA accmulate factor of C
 * @param setup_SSR setup SSR bounds and strides
 * @return * void
 */
void gemm_fp32simd_tb_ssr_frep(const uint32_t M, const uint32_t N,
                               const uint32_t K, float* A, const uint32_t ldA,
                               float* B, const uint32_t ldB, float* C,
                               const uint32_t ldC, const uint32_t* ALPHA,
                               const uint32_t setup_SSR) {
    register volatile double ft0 asm("ft0");
    register volatile double ft1 asm("ft1");
    register volatile double ft2 asm("ft2");
    asm volatile("" : "=f"(ft0), "=f"(ft1), "=f"(ft2));

    // Unrolling factor of most inner loop.
    // Should be at least as high as the FMA delay
    // for maximum utilization
    const uint32_t unroll = 8;

    // SSR strides and bounds only have to be configured
    // once in the beginning
    if (setup_SSR) {
        uint32_t ssr0_b[4] = {unroll, K / 2, N / unroll, M};
        uint32_t ssr0_i[4] = {0, sizeof(float) * 2, 0, sizeof(float) * ldA};

        uint32_t ssr1_b[4] = {unroll, K / 2, N / unroll, M};
        uint32_t ssr1_i[4] = {sizeof(float) * ldB, sizeof(float) * 2,
                              sizeof(float) * unroll * ldB, 0};

        snrt_ssr_loop_3d(SNRT_SSR_DM0, ssr0_b[1], ssr0_b[2], ssr0_b[3],
                         ssr0_i[1], ssr0_i[2], ssr0_i[3]);
        snrt_ssr_repeat(SNRT_SSR_DM0, unroll);

        snrt_ssr_loop_4d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2],
                         ssr1_b[3], ssr1_i[0], ssr1_i[1], ssr1_i[2], ssr1_i[3]);
    }

    // SSR start address need to be configured each time
    snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_4D, A);
    snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_4D, B);
    snrt_ssr_enable();

    // Kernel progresses by 2 values each step
    const uint32_t n_frep = K / 2 - 1;

    for (uint32_t m = 0; m < M; m++) {
        uint32_t n = 0;
        for (uint32_t n0 = 0; n0 < N / unroll; n0++) {
            float* _C = &C[m * ldC + n / 2];
            const register float zero = 0.0;
            register v2f32 c[unroll], reduce_reg[unroll];

            asm volatile(
                "lw      t0, 0(%[ALPHA]) \n"
                "beqz    t0, 1f \n"
                // Load intermediate results
                "flw %[reduce_reg0], 0(%[C]) \n"
                "flw %[reduce_reg1], 4(%[C]) \n"
                "flw %[reduce_reg2], 8(%[C]) \n"
                "flw %[reduce_reg3], 12(%[C]) \n"
                "flw %[reduce_reg4], 16(%[C]) \n"
                "flw %[reduce_reg5], 20(%[C]) \n"
                "flw %[reduce_reg6], 24(%[C]) \n"
                "flw %[reduce_reg7], 28(%[C]) \n"
                // Pack intermediate results into SIMD vector
                "vfcpka.s.s %[reduce_reg0], %[reduce_reg0], %[zero]\n"
                "vfcpka.s.s %[reduce_reg1], %[reduce_reg1], %[zero]\n"
                "vfcpka.s.s %[reduce_reg2], %[reduce_reg2], %[zero]\n"
                "vfcpka.s.s %[reduce_reg3], %[reduce_reg3], %[zero]\n"
                "vfcpka.s.s %[reduce_reg4], %[reduce_reg4], %[zero]\n"
                "vfcpka.s.s %[reduce_reg5], %[reduce_reg5], %[zero]\n"
                "vfcpka.s.s %[reduce_reg6], %[reduce_reg6], %[zero]\n"
                "vfcpka.s.s %[reduce_reg7], %[reduce_reg7], %[zero]\n"
                "j 2f \n"
                "1: \n"
                // Initialize SIMD vector with zeros
                "vfcpka.s.s %[reduce_reg0], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg1], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg2], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg3], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg4], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg5], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg6], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg7], %[zero], %[zero]\n"

                "2: \n"
                // Don't accumulate in first iteration
                "vfmul.s %[c0], ft1, ft0 \n"
                "vfmul.s %[c1], ft1, ft0 \n"
                "vfmul.s %[c2], ft1, ft0 \n"
                "vfmul.s %[c3], ft1, ft0 \n"
                "vfmul.s %[c4], ft1, ft0 \n"
                "vfmul.s %[c5], ft1, ft0 \n"
                "vfmul.s %[c6], ft1, ft0 \n"
                "vfmul.s %[c7], ft1, ft0 \n"
                // frep over MACs
                "frep.o  %[n_frep], 8, 0, 0 \n"
                "vfmac.s %[c0], ft1, ft0 \n"
                "vfmac.s %[c1], ft1, ft0 \n"
                "vfmac.s %[c2], ft1, ft0 \n"
                "vfmac.s %[c3], ft1, ft0 \n"
                "vfmac.s %[c4], ft1, ft0 \n"
                "vfmac.s %[c5], ft1, ft0 \n"
                "vfmac.s %[c6], ft1, ft0 \n"
                "vfmac.s %[c7], ft1, ft0 \n"
                // Sum-reduce vector
                "vfsum.s %[reduce_reg0], %[c0] \n"
                "vfsum.s %[reduce_reg1], %[c1] \n"
                "vfsum.s %[reduce_reg2], %[c2] \n"
                "vfsum.s %[reduce_reg3], %[c3] \n"
                "vfsum.s %[reduce_reg4], %[c4] \n"
                "vfsum.s %[reduce_reg5], %[c5] \n"
                "vfsum.s %[reduce_reg6], %[c6] \n"
                "vfsum.s %[reduce_reg7], %[c7] \n"
                // Pack results together again into vectors
                "vfcpka.s.s %[c0], %[reduce_reg0], %[reduce_reg1] \n"
                "vfcpka.s.s %[c1], %[reduce_reg2], %[reduce_reg3] \n"
                "vfcpka.s.s %[c2], %[reduce_reg4], %[reduce_reg5] \n"
                "vfcpka.s.s %[c3], %[reduce_reg6], %[reduce_reg7] \n"
                : [ c0 ] "+f"(c[0]), [ c1 ] "+f"(c[1]), [ c2 ] "+f"(c[2]),
                  [ c3 ] "+f"(c[3]), [ c4 ] "+f"(c[4]), [ c5 ] "+f"(c[5]),
                  [ c6 ] "+f"(c[6]), [ c7 ] "+f"(c[7]),
                  [ reduce_reg0 ] "+f"(reduce_reg[0]),
                  [ reduce_reg1 ] "+f"(reduce_reg[1]),
                  [ reduce_reg2 ] "+f"(reduce_reg[2]),
                  [ reduce_reg3 ] "+f"(reduce_reg[3]),
                  [ reduce_reg4 ] "+f"(reduce_reg[4]),
                  [ reduce_reg5 ] "+f"(reduce_reg[5]),
                  [ reduce_reg6 ] "+f"(reduce_reg[6]),
                  [ reduce_reg7 ] "+f"(reduce_reg[7])
                : [ C ] "r"(_C), [ zero ] "f"(zero), [ n_frep ] "r"(n_frep - 1),
                  [ ALPHA ] "r"(ALPHA)
                : "ft0", "ft1", "ft2");

            // Store results
            ((v2f32*)_C)[0] = c[0];
            ((v2f32*)_C)[1] = c[1];
            ((v2f32*)_C)[2] = c[2];
            ((v2f32*)_C)[3] = c[3];

            // progress by 2 columns each iteration of the loop
            n += unroll * 2;
        }

        // Clean up of leftover columns
        snrt_ssr_disable();

        for (; n < N; n++) {
            float c = (*ALPHA) ? C[m * ldC + n] : 0.0;
            for (uint32_t k = 0; k < K; k++) {
                c += A[k + m * ldA] * B[k + n * ldB];
            }
            C[m * ldC + n] = c;
        }

        snrt_ssr_enable();
    }

    snrt_ssr_disable();

    asm volatile("" ::"f"(ft0), "f"(ft1), "f"(ft2));
}

/**
 * @brief implementation of a FP16 SIMD GEMM with configured
 * SSRs and frep loop. Matrix B has to be stored in transposed/consecutive
 * memory layout in order to support SIMD instructions.
 *
 * @param M number of rows of matrix A
 * @param N number of columns of matrix B
 * @param K number of columns of matrix A
 * @param A pointer to matrix A
 * @param ldA row stride in matrix A
 * @param B pointer to matrix B
 * @param ldB row stride in matrix B
 * @param C pointer to matrix C
 * @param ldC row stride in matrix C
 * @param ALPHA accmulate factor of C
 * @param setup_SSR setup SSR bounds and strides
 * @return * void
 */
void gemm_fp16simd_tb_ssr_frep(uint32_t M, uint32_t N, uint32_t K, __fp16* A,
                               uint32_t ldA, __fp16* B, uint32_t ldB, __fp16* C,
                               uint32_t ldC, const uint32_t* ALPHA,
                               uint32_t setup_SSR) {
    register volatile double ft0 asm("ft0");
    register volatile double ft1 asm("ft1");
    register volatile double ft2 asm("ft2");
    asm volatile("" : "=f"(ft0), "=f"(ft1), "=f"(ft2));

    // Unrolling factor of most inner loop.
    // Should be at least as high as the FMA delay
    // for maximum utilization
    const uint32_t unroll = 8;

    // SSR strides and bounds only have to be configured
    // once in the beginning
    if (setup_SSR) {
        uint32_t ssr0_b[4] = {unroll, K / 4, N / unroll, M};
        uint32_t ssr0_i[4] = {0, sizeof(__fp16) * 4, 0, sizeof(__fp16) * ldA};

        uint32_t ssr1_b[4] = {unroll, K / 4, N / unroll, M};
        uint32_t ssr1_i[4] = {sizeof(__fp16) * ldB, sizeof(__fp16) * 4,
                              sizeof(__fp16) * unroll * ldB, 0};

        snrt_ssr_loop_3d(SNRT_SSR_DM0, ssr0_b[1], ssr0_b[2], ssr0_b[3],
                         ssr0_i[1], ssr0_i[2], ssr0_i[3]);
        snrt_ssr_repeat(SNRT_SSR_DM0, unroll);

        snrt_ssr_loop_4d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2],
                         ssr1_b[3], ssr1_i[0], ssr1_i[1], ssr1_i[2], ssr1_i[3]);
    }

    // SSR start address need to be configured each time
    snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_4D, A);
    snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_4D, B);
    snrt_ssr_enable();

    // Kernel progresses by 4 values each step
    const uint32_t n_frep = K / 4 - 1;

    for (uint32_t m = 0; m < M; m++) {
        uint32_t n = 0;
        for (uint32_t n0 = 0; n0 < N / unroll; n0++) {
            __fp16* _C = &C[m * ldC + n];
            const register float zero = 0.0;
            register v4f16 c[unroll];
            register v2f32 reduce_reg[unroll];
            uint32_t alpha;

            asm volatile(
                "lw      %[alpha], 0(%[ALPHA]) \n"
                "beqz    %[alpha], 1f \n"
                // Load intermediate results
                "flw %[c0], 0(%[C]) \n"
                "flw %[c1], 4(%[C]) \n"
                "flw %[c2], 8(%[C]) \n"
                "flw %[c3], 12(%[C]) \n"
                "flw %[c4], 16(%[C]) \n"
                "flw %[c5], 20(%[C]) \n"
                "flw %[c6], 24(%[C]) \n"
                "flw %[c7], 28(%[C]) \n"
                // Pack intermediate results into SIMD vector
                "vfcpka.s.s %[c0], %[c0], %[zero]\n"
                "vfcpka.s.s %[c1], %[c1], %[zero]\n"
                "vfcpka.s.s %[c2], %[c2], %[zero]\n"
                "vfcpka.s.s %[c3], %[c3], %[zero]\n"
                "vfcpka.s.s %[c4], %[c4], %[zero]\n"
                "vfcpka.s.s %[c5], %[c5], %[zero]\n"
                "vfcpka.s.s %[c6], %[c6], %[zero]\n"
                "vfcpka.s.s %[c7], %[c7], %[zero]\n"
                "j 2f \n"
                "1: \n"
                // Initialize SIMD vector with zeros
                "vfcpka.s.s %[c0], %[zero], %[zero]\n"
                "vfcpka.s.s %[c1], %[zero], %[zero]\n"
                "vfcpka.s.s %[c2], %[zero], %[zero]\n"
                "vfcpka.s.s %[c3], %[zero], %[zero]\n"
                "vfcpka.s.s %[c4], %[zero], %[zero]\n"
                "vfcpka.s.s %[c5], %[zero], %[zero]\n"
                "vfcpka.s.s %[c6], %[zero], %[zero]\n"
                "vfcpka.s.s %[c7], %[zero], %[zero]\n"
                "2: \n"
                // Perform expanding sum-dotproducts
                "frep.o  %[n_frep], 8, 0, 0 \n"
                "vfdotpex.s.h %[c0], ft1, ft0 \n"
                "vfdotpex.s.h %[c1], ft1, ft0 \n"
                "vfdotpex.s.h %[c2], ft1, ft0 \n"
                "vfdotpex.s.h %[c3], ft1, ft0 \n"
                "vfdotpex.s.h %[c4], ft1, ft0 \n"
                "vfdotpex.s.h %[c5], ft1, ft0 \n"
                "vfdotpex.s.h %[c6], ft1, ft0 \n"
                "vfdotpex.s.h %[c7], ft1, ft0 \n"
                // Initialize reduce register to zero
                "vfcpka.s.s %[reduce_reg0], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg1], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg2], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg3], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg4], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg5], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg6], %[zero], %[zero]\n"
                "vfcpka.s.s %[reduce_reg7], %[zero], %[zero]\n"
                // Sum-reduce vector
                "vfsum.s %[reduce_reg0], %[c0] \n"
                "vfsum.s %[reduce_reg1], %[c1] \n"
                "vfsum.s %[reduce_reg2], %[c2] \n"
                "vfsum.s %[reduce_reg3], %[c3] \n"
                "vfsum.s %[reduce_reg4], %[c4] \n"
                "vfsum.s %[reduce_reg5], %[c5] \n"
                "vfsum.s %[reduce_reg6], %[c6] \n"
                "vfsum.s %[reduce_reg7], %[c7] \n"
                // Pack and convert results to FP16 vectors
                "vfcpka.h.s %[c0], %[reduce_reg0], %[reduce_reg1] \n"
                "vfcpkb.h.s %[c0], %[reduce_reg2], %[reduce_reg3] \n"
                "vfcpka.h.s %[c1], %[reduce_reg4], %[reduce_reg5] \n"
                "vfcpkb.h.s %[c1], %[reduce_reg6], %[reduce_reg7] \n"
                : [ c0 ] "+f"(c[0]), [ c1 ] "+f"(c[1]), [ c2 ] "+f"(c[2]),
                  [ c3 ] "+f"(c[3]), [ c4 ] "+f"(c[4]), [ c5 ] "+f"(c[5]),
                  [ c6 ] "+f"(c[6]), [ c7 ] "+f"(c[7]), [ alpha ] "=r"(alpha),
                  [ reduce_reg0 ] "+f"(reduce_reg[0]),
                  [ reduce_reg1 ] "+f"(reduce_reg[1]),
                  [ reduce_reg2 ] "+f"(reduce_reg[2]),
                  [ reduce_reg3 ] "+f"(reduce_reg[3]),
                  [ reduce_reg4 ] "+f"(reduce_reg[4]),
                  [ reduce_reg5 ] "+f"(reduce_reg[5]),
                  [ reduce_reg6 ] "+f"(reduce_reg[6]),
                  [ reduce_reg7 ] "+f"(reduce_reg[7])
                : [ C ] "r"(_C), [ zero ] "f"(zero), [ n_frep ] "r"(n_frep),
                  [ ALPHA ] "r"(ALPHA)
                : "ft0", "ft1", "ft2");

            // Store results back
            ((v4f16*)_C)[0] = c[0];
            ((v4f16*)_C)[1] = c[1];
            n += unroll;
        }

        // Clean up left over column
        snrt_ssr_disable();

        for (; n < N; n++) {
            __fp16 c = (*ALPHA) ? C[m * ldC + n] : 0.0;
            for (uint32_t k = 0; k < K; k++) {
                c += A[k + m * ldA] * B[k + n * ldB];
            }
            C[m * ldC + n] = c;
        }

        snrt_ssr_enable();
    }

    snrt_ssr_disable();

    asm volatile("" ::"f"(ft0), "f"(ft1), "f"(ft2));
}
