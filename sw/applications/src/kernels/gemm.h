// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

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
               uint32_t ldC, const double ALPHA);

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
                        const uint32_t* ALPHA, uint32_t setup_SSR);

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
                               const uint32_t setup_SSR);

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
                               uint32_t setup_SSR);
