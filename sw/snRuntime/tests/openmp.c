// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "encoding.h"
#include "eu.h"
#include "omp.h"
#include "printf.h"
#include "snrt.h"

#define AXPY_N 64

// #define tprintf(...) printf(__VA_ARGS__)
#define tprintf(...) while (0)

volatile static uint32_t sum = 0;

unsigned __attribute__((noinline)) static_schedule(void) {
    static double data_x[AXPY_N], data_y[AXPY_N], data_a;

    // Init data
    data_a = 10.0;
    for (unsigned i = 0; i < AXPY_N; i++) {
        data_x[i] = (double)(i);
        data_y[i] = (double)(i + 1);
    }

    // compute
#pragma omp parallel
    {
        __builtin_ssr_setup_1d_r(0, 0, AXPY_N - 1, sizeof(double),
                                 &data_x[AXPY_N / 8 * omp_get_thread_num()]);
        __builtin_ssr_setup_1d_r(1, 0, AXPY_N - 1, sizeof(double),
                                 &data_y[AXPY_N / 8 * omp_get_thread_num()]);
        __builtin_ssr_enable();
#pragma omp for schedule(static)
        for (unsigned i = 0; i < AXPY_N; i++) {
            // data_y[i] = data_a * data_x[i] + data_y[i];
            data_y[i] = data_a * __builtin_ssr_pop(0) + __builtin_ssr_pop(1);
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

    if (errs) tprintf("Error [static_schedule]: %d mismatches\n", errs);
    return errs ? 1 : 0;
}

unsigned __attribute__((noinline)) paralell_section(void) {
    unsigned tx = read_csr(minstret);
    static volatile uint32_t sum = 0;

// the following code is executed by all harts
#pragma omp parallel
    {
        tx = read_csr(minstret) - tx;
        __atomic_add_fetch(&sum, 10, __ATOMIC_RELAXED);
    }
    return sum != 8 * 10;
}

int main() {
    unsigned core_idx = snrt_cluster_core_idx();
    unsigned core_num = snrt_cluster_core_num();
    unsigned err = 0;

    __snrt_omp_bootstrap(core_idx);

    // Static schedule test
    err |= static_schedule() << 0;
    // Launch overhead test
    err |= paralell_section() << 1;

    // exit
    __snrt_omp_destroy(core_idx);
    return err;
}
