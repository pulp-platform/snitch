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
    // pulp_ssr_loop_4d(SSR_DM0, 4, K, M/4, N, 0, 8,     0*4, 8*ldA);
    //                                   K      M    N
    pulp_ssr_loop_3d(SSR_DM0, K, M / 4, N, 8, 0 * 4, 8 * ldA);
    ssr_config_reg[SSR_DM0].repeat.value = 3;  // repeat value 4 times
    //                                      4  K      M    N
    pulp_ssr_loop_4d(SSR_DM1, 4, K, M / 4, N, 8, 8 * ldB, 8 * 4, 0);
    pulp_ssr_read(SSR_DM0, SSR_3D, A);
    pulp_ssr_read(SSR_DM1, SSR_4D, B);
    // pulp_ssr_loop_3d(SSR_DM0, K, M, N, 8, 0, 8*ldA);
    // pulp_ssr_loop_3d(SSR_DM1, K, M, N, 8*ldB, 8, 0);
    // pulp_ssr_read(SSR_DM0, SSR_3D, A);
    // pulp_ssr_read(SSR_DM1, SSR_3D, B);
    pulp_ssr_enable();

    const register uint32_t Km1 asm("t0") = K - 1;
    for (uint32_t n = 0; n < N; n++) {
        for (uint32_t m = 0; m < M; m += 4) {
            register double c0 = C[n * ldC + m + 0];
            register double c1 = C[n * ldC + m + 1];
            register double c2 = C[n * ldC + m + 2];
            register double c3 = C[n * ldC + m + 3];
            asm volatile(
                ".word (3 << 20)|(5 << 15)|(1 << 7)|(0b0001011 << 0) \n"  // frep
                                                                          // t0,
                                                                          // 4
                "fmadd.d %[c0], ft0, ft1, %[c0] \n"
                "fmadd.d %[c1], ft0, ft1, %[c1] \n"
                "fmadd.d %[c2], ft0, ft1, %[c2] \n"
                "fmadd.d %[c3], ft0, ft1, %[c3] \n"
                : [ c0 ] "+f"(c0), [ c1 ] "+f"(c1), [ c2 ] "+f"(c2),
                  [ c3 ] "+f"(c3)
                : [ K ] "r"(Km1)
                : "ft0", "ft1");
            C[n * ldC + m + 0] = c0;
            C[n * ldC + m + 1] = c1;
            C[n * ldC + m + 2] = c2;
            C[n * ldC + m + 3] = c3;
        }
    }

    // End of SSR region.
    fpu_fence();
    pulp_ssr_disable();
    asm volatile("" ::"f"(ft0), "f"(ft1));
}

#include "matmul/main.c"
