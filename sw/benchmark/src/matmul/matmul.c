// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "matmul.h"

extern uint32_t input_size;
extern double output_checksum[];

static void populate(double *ptr, uint32_t size, uint32_t seed) {
    for (uint32_t i = 0; i < size; i++) {
        *ptr = (double)seed * 3.141;
        ++ptr;
        ++seed;
    }
}

gemm_result_t gemm_bench(gemm_impl_t gemm_impl) {
    snrt_cluster_hw_barrier();
    size_t core_id = snrt_cluster_compute_core_idx();
    size_t core_num = snrt_cluster_compute_core_num();

    if(snrt_is_dm_core()) {
        snrt_cluster_hw_barrier();
        snrt_cluster_hw_barrier();
        return (gemm_result_t){0,0,0};
    }

    // Allocate buffer memory in the TCDM and generate input data.
    double *ptr = snrt_cluster_memory().start;
    double *input_A = ptr;
    ptr += input_size * input_size + 1;
    double *input_B = ptr;
    ptr += input_size * input_size + 1;
    double *input_C = ptr;
    ptr += input_size * input_size + 1;
    if (core_id % core_num == 0) populate(input_A, input_size * input_size, 1);
    if (core_id % core_num == 1) populate(input_B, input_size * input_size, 2);
    if (core_id % core_num == 2) populate(input_C, input_size * input_size, 3);

    // Parallelize computation across the cores.
    uint32_t N = input_size / core_num;
    uint32_t M = input_size;
    uint32_t K = input_size;
    double *argA = input_A + core_id * input_size;
    double *argB = input_B;
    double *argC = input_C + core_id * input_size;
    uint32_t ldA = input_size * core_num;
    uint32_t ldB = input_size;
    uint32_t ldC = input_size * core_num;

    // Execute the kernel and measure time.
    size_t t0 = benchmark_get_cycle();
    snrt_cluster_hw_barrier();
    size_t t1 = benchmark_get_cycle();
    gemm_impl(N, M, K, argA, ldA, argB, ldB, argC, ldC);
    size_t t2 = benchmark_get_cycle();
    snrt_cluster_hw_barrier();
    size_t t3 = benchmark_get_cycle();

    // Check and return results.
    uint32_t diffs = 0;
    if (core_id == 0) {
        for (uint32_t i = 0; i < input_size; i++) {
            double sum = 0;
            for (uint32_t n = 0; n < input_size; n++) {
                sum += input_C[i * input_size + n];
            }
            double d = sum - output_checksum[i];
            asm volatile("fabs.d %[d], %[d]" : [ d ] "+f"(d));
            diffs += d > 0.001;
        }
    }
    return (gemm_result_t){
        .errors = diffs,
        .cycles_core = t2 - t1,
        .cycles_total = t3 - t0,
    };
}

void gemm_seq_baseline(uint32_t N, uint32_t M, uint32_t K, double *restrict A,
                       uint32_t ldA, double *restrict B, uint32_t ldB,
                       double *restrict C, uint32_t ldC) {
    // We are restricted to two as we unrolled
    // the loop manually.
    const uint32_t tf = 2;

    for (uint32_t n1 = 0; n1 < N; n1 += tf) {
        for (uint32_t m1 = 0; m1 < M; m1 += tf) {
            for (uint32_t k1 = 0; k1 < K; k1 += tf) {
                asm volatile("loop_start:");
                asm volatile(
                    "fld    ft0,0(%[a0]) \n"
                    "fld    ft1,8(%[a0]) \n"
                    "fld    ft2,0(%[a1]) \n"
                    "fld    ft3,8(%[a1]) \n"
                    "fld    ft4,0(%[b0]) \n"
                    "fld    ft5,8(%[b0]) \n"
                    "fld    ft6,0(%[b1]) \n"
                    "fld    ft7,8(%[b1]) \n"
                    "fld    fs0,0(%[c0]) \n"
                    "fld    fs1,8(%[c0]) \n"
                    "fld    fs2,0(%[c1]) \n"
                    "fld    fs3,8(%[c1]) \n"
                    "fmadd.d    fs0, ft0, ft4, fs0 \n"
                    "fmadd.d    fs1, ft0, ft5, fs1 \n"
                    "fmadd.d    fs2, ft2, ft4, fs2 \n"
                    "fmadd.d    fs3, ft2, ft5, fs3 \n"
                    "fmadd.d    fs0, ft1, ft6, fs0 \n"
                    "fmadd.d    fs1, ft1, ft7, fs1 \n"
                    "fmadd.d    fs2, ft3, ft6, fs2 \n"
                    "fmadd.d    fs3, ft3, ft7, fs3 \n"
                    "fsd    fs0,0(%[c0]) \n"
                    "fsd    fs1,8(%[c0]) \n"
                    "fsd    fs2,0(%[c1]) \n"
                    "fsd    fs3,8(%[c1]) \n"
                    :
                    : [ a0 ] "r"(&A[(n1 + 0) * ldA + (k1)]),
                      [ a1 ] "r"(&A[(n1 + 1) * ldA + (k1)]),
                      [ b0 ] "r"(&B[(k1 + 0) * ldB + (m1)]),
                      [ b1 ] "r"(&B[(k1 + 1) * ldB + (m1)]),
                      [ c0 ] "r"(&C[(n1 + 0) * ldC + (m1)]),
                      [ c1 ] "r"(&C[(n1 + 1) * ldC + (m1)])
                    : "ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6", "ft7",
                      "fs0", "fs1", "fs2", "fs3", "memory");
                // Unrolled C version. Bubbles a lot due to data dependencies.
                // Probably the compiler which is a bit stupid and has no proper
                // instruction schedule for the core. for (uint32_t n2 = 0; n2 <
                // tf; n2++) {
                //     for (uint32_t m2 = 0; m2 < tf; m2++) {
                //         double c = C[(n1+n2)*ldC+(m1+m2)];
                //         for (uint32_t k2 = 0; k2 < tf; k2++) {
                //             // c += A[(n1+n2)*ldA+(k1+k2)] *
                //             B[(k1+k2)*ldB+(m1+m2)]; asm ("fmadd.d %[c], %[A],
                //             %[B], %[c]"
                //                 : [c]"+f"(c)
                //                 : [A]"f"(A[(n1+n2)*ldA+(k1+k2)]),
                //                 [B]"f"(B[(k1+k2)*ldB+(m1+m2)]));
                //         }
                //         C[(n1+n2)*ldC+(m1+m2)] = c;
                //     }
                // }
                asm volatile("loop_end:");
            }
        }
    }
}

void gemm_seq_ssr(uint32_t N, uint32_t M, uint32_t K, double *A, uint32_t ldA,
                  double *B, uint32_t ldB, double *C, uint32_t ldC) {
    // Start of SSR region.
    register volatile double ft0 asm("ft0");
    register volatile double ft1 asm("ft1");
    asm volatile("" : "=f"(ft0), "=f"(ft1));

    snrt_ssr_loop_3d(SNRT_SSR_DM0, K, M / 4, N, 8, 0 * 4, 8 * ldA);
    snrt_ssr_repeat(SNRT_SSR_DM0, 4);  // repeat value 4 times
    snrt_ssr_loop_4d(SNRT_SSR_DM1, 4, K, M / 4, N, 8, 8 * ldB, 8 * 4, 0);
    snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_3D, A);
    snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_4D, B);
    snrt_ssr_enable();

    for (uint32_t n = 0; n < N; n++) {
        for (uint32_t m = 0; m < M; m += 4) {
            register double c0 = C[n * ldC + m + 0];
            register double c1 = C[n * ldC + m + 1];
            register double c2 = C[n * ldC + m + 2];
            register double c3 = C[n * ldC + m + 3];
            for (uint32_t k = 0; k < K; k++) {
                asm volatile(
                    "fmadd.d %[c0], ft0, ft1, %[c0] \n"
                    "fmadd.d %[c1], ft0, ft1, %[c1] \n"
                    "fmadd.d %[c2], ft0, ft1, %[c2] \n"
                    "fmadd.d %[c3], ft0, ft1, %[c3] \n"
                    : [ c0 ] "+f"(c0), [ c1 ] "+f"(c1), [ c2 ] "+f"(c2),
                      [ c3 ] "+f"(c3)::"ft0", "ft1",
                      "ft2");  // clobber ft0..ft2 for 3 SSR streamers
            }
            C[n * ldC + m + 0] = c0;
            C[n * ldC + m + 1] = c1;
            C[n * ldC + m + 2] = c2;
            C[n * ldC + m + 3] = c3;
        }
    }

    // End of SSR region.
    snrt_ssr_disable();
    asm volatile("" ::"f"(ft0), "f"(ft1));
}

void gemm_seq_ssr_frep(uint32_t N, uint32_t M, uint32_t K, double *A,
                       uint32_t ldA, double *B, uint32_t ldB, double *C,
                       uint32_t ldC) {
    // Start of SSR region.
    register volatile double ft0 asm("ft0");
    register volatile double ft1 asm("ft1");
    asm volatile("" : "=f"(ft0), "=f"(ft1));

    snrt_ssr_loop_3d(SNRT_SSR_DM0, K, M / 4, N, 8, 0 * 4, 8 * ldA);
    snrt_ssr_repeat(SNRT_SSR_DM0, 4);  // repeat value 4 times
    snrt_ssr_loop_4d(SNRT_SSR_DM1, 4, K, M / 4, N, 8, 8 * ldB, 8 * 4, 0);
    snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_3D, A);
    snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_4D, B);
    snrt_ssr_enable();

    register const uint32_t Km1 asm("t0") = K - 1;
    for (uint32_t n = 0; n < N; n++) {
        for (uint32_t m = 0; m < M; m += 4) {
            register double c0 = C[n * ldC + m + 0];
            register double c1 = C[n * ldC + m + 1];
            register double c2 = C[n * ldC + m + 2];
            register double c3 = C[n * ldC + m + 3];
            asm volatile(
                // frep t0, 4
                ".word (3 << 20)|(5 << 15)|(1 << 7)|(0b0001011 << 0) \n"
                "fmadd.d %[c0], ft0, ft1, %[c0] \n"
                "fmadd.d %[c1], ft0, ft1, %[c1] \n"
                "fmadd.d %[c2], ft0, ft1, %[c2] \n"
                "fmadd.d %[c3], ft0, ft1, %[c3] \n"
                : [ c0 ] "+f"(c0), [ c1 ] "+f"(c1), [ c2 ] "+f"(c2),
                  [ c3 ] "+f"(c3)
                : [ K ] "r"(Km1)
                : "ft0", "ft1", "ft2");  // clobber ft0..ft2 for 3 SSR streamers
            C[n * ldC + m + 0] = c0;
            C[n * ldC + m + 1] = c1;
            C[n * ldC + m + 2] = c2;
            C[n * ldC + m + 3] = c3;
        }
    }

    // End of SSR region.
    snrt_fpu_fence();
    snrt_ssr_disable();
    asm volatile("" ::"f"(ft0), "f"(ft1));
}
