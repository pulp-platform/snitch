// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once
#include "benchmark.h"

extern uint32_t input_size;
extern double output_checksum[];

typedef struct {
    size_t errors;
    size_t cycles_core;
    size_t cycles_total;
} gemm_result_t;

typedef void (*gemm_impl_t)(uint32_t N, uint32_t M, uint32_t K, double *A,
                            uint32_t ldA, double *B, uint32_t ldB, double *C,
                            uint32_t ldC);

gemm_result_t gemm_bench(gemm_impl_t gemm_impl);

void gemm_seq_baseline(uint32_t N, uint32_t M, uint32_t K, double *restrict A,
                       uint32_t ldA, double *restrict B, uint32_t ldB,
                       double *restrict C, uint32_t ldC);

void gemm_seq_ssr(uint32_t N, uint32_t M, uint32_t K, double *restrict A,
                  uint32_t ldA, double *restrict B, uint32_t ldB,
                  double *restrict C, uint32_t ldC);

void gemm_seq_ssr_frep(uint32_t N, uint32_t M, uint32_t K, double *restrict A,
                       uint32_t ldA, double *restrict B, uint32_t ldB,
                       double *restrict C, uint32_t ldC);
