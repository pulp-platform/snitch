// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

void batchnorm_fp64(double *ifmap, double *gamma, double *beta, double *ofmap,
                    uint32_t OW, uint32_t CI, uint32_t compute_num,
                    uint32_t setup_SSR) {
    // initial SSR setup
    if (setup_SSR) {
        uint32_t ssr_b[2] = {OW, CI / compute_num};
        uint32_t ssr_i[2] = {CI * sizeof(double), compute_num * sizeof(double)};

        snrt_ssr_loop_2d(SNRT_SSR_DM0, ssr_b[0], ssr_b[1], ssr_i[0], ssr_i[1]);
        snrt_ssr_loop_2d(SNRT_SSR_DM1, ssr_b[0], ssr_b[1], ssr_i[0], ssr_i[1]);
    }

    // SSR address setup
    snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_2D, ifmap);
    snrt_ssr_write(SNRT_SSR_DM1, SNRT_SSR_2D, ofmap);
    snrt_ssr_enable();

    for (uint32_t ci = 0; ci < CI; ci += compute_num) {
        register double g = gamma[ci];
        register double b = beta[ci];

        // frep over OW dimension
        asm volatile(
            "frep.o %[n_frep], 1, 0, 0 \n"
            "fmadd.d ft1, ft0, %[g], %[b] \n" ::[g] "f"(g),
            [ b ] "f"(b), [ n_frep ] "r"(OW - 1)
            : "ft0", "ft1", "ft2");
    }
    snrt_fpu_fence();
    __builtin_ssr_barrier(SNRT_SSR_DM1);
    snrt_ssr_disable();
}
