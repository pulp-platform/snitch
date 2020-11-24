// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

static void gemm_seq(
	uint32_t N, uint32_t M, uint32_t K,
	double *A, uint32_t ldA,
	double *B, uint32_t ldB,
	double *C, uint32_t ldC
) {
    for (uint32_t n = 0; n < N; n++) {
        for (uint32_t m = 0; m < M; m++) {
            double c = C[n*ldC+m];
            for (uint32_t k = 0; k < K; k++) {
                c += A[n*ldA+k] * B[k*ldB+m];
            }
            C[n*ldC+m] = c;
        }
    }
}

#include "matmul/main.c"
