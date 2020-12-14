// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

void gemm_seq(uint32_t N, uint32_t M, uint32_t K, double *A, uint32_t ldA,
              double *B, uint32_t ldB, double *C, uint32_t ldC) {
    // Start of SSR region.
    register volatile double ft0 asm("ft0");
    register volatile double ft1 asm("ft1");
    asm volatile("" : "=f"(ft0), "=f"(ft1));

    pulp_ssr_loop_3d(SSR_DM0, K, M, N, 8, 0, 8 * ldA);
    pulp_ssr_loop_3d(SSR_DM1, K, M, N, 8 * ldB, 8, 0);
    pulp_ssr_read(SSR_DM0, SSR_3D, A);
    pulp_ssr_read(SSR_DM1, SSR_3D, B);
    pulp_ssr_enable();

    for (uint32_t n = 0; n < N; n++) {
        for (uint32_t m = 0; m < M; m++) {
            double c = C[n * ldC + m];
            for (uint32_t k = 0; k < K; k++) {
                asm volatile("fmadd.d %[c], ft0, ft1, %[c]"
                             : [ c ] "+f"(c)::"ft0", "ft1");
            }
            C[n * ldC + m] = c;
        }
    }

    // End of SSR region.
    pulp_ssr_disable();
    asm volatile("" ::"f"(ft0), "f"(ft1));
}

#include "matmul/main.c"
