// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

#define AXPY_N 64
#define NTHREADS 8

unsigned __attribute__((noinline)) static_schedule(void) {
    static double *data_x, *data_y, data_a;

    // Allocate AXPY input vectors
    data_x = snrt_l1alloc(sizeof(double) * AXPY_N);
    data_y = snrt_l1alloc(sizeof(double) * AXPY_N);

    // Initialize AXPY input vectors
    data_a = 10.0;
    for (unsigned i = 0; i < AXPY_N; i++) {
        data_x[i] = (double)(i);
        data_y[i] = (double)(i + 1);
    }

    // Compute AXPY
#pragma omp parallel firstprivate(data_a, data_x, data_y)
    {
        // DM, rep, bound, stride, data
        __builtin_ssr_setup_1d_r(0, 0, AXPY_N / NTHREADS - 1, sizeof(double),
                                 &data_x[AXPY_N / 8 * omp_get_thread_num()]);
        __builtin_ssr_setup_1d_r(1, 0, AXPY_N / NTHREADS - 1, sizeof(double),
                                 &data_y[AXPY_N / 8 * omp_get_thread_num()]);
        __builtin_ssr_setup_1d_w(2, 0, AXPY_N / NTHREADS - 1, sizeof(double),
                                 &data_y[AXPY_N / 8 * omp_get_thread_num()]);
        __builtin_ssr_enable();
#pragma omp for schedule(static)
        for (unsigned i = 0; i < AXPY_N; i++) {
            // data_y[i] = data_a * data_x[i] + data_y[i];
            // data_y[i] = data_a * __builtin_ssr_pop(0) +
            __builtin_ssr_pop(1);
            __builtin_ssr_push(
                2, data_a * __builtin_ssr_pop(0) + __builtin_ssr_pop(1));
        }
        __builtin_ssr_disable();
    }

    // check data
    unsigned errs = 0;
    double gold;
    for (unsigned i = 0; i < AXPY_N; i++) {
        gold = 10.0 * (double)(i) + (double)(i + 1);
        if ((gold - data_y[i]) * (gold - data_y[i]) > 0.01) errs++;
    }

    if (errs) printf("Error [static_schedule]: %d mismatches\n", errs);
    return errs ? 1 : 0;
}

int main() {
    unsigned core_idx = snrt_cluster_core_idx();
    unsigned core_num = snrt_cluster_core_num();
    unsigned err = 0;

    // Only core 0 executes the statements below this function
    __snrt_omp_bootstrap(core_idx);

    printf("Static schedule test\n");
    err = static_schedule();
    OMP_PROF(omp_print_prof());

    // exit
    __snrt_omp_destroy(core_idx);
    return err;
}
