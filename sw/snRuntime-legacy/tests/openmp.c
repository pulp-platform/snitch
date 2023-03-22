// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "dm.h"
#include "encoding.h"
#include "eu.h"
#include "omp.h"
#include "printf.h"
#include "snrt.h"

#define AXPY_N 64
#define NUMTHREADS 8

// Test output printf
#define tprintf(...) printf(__VA_ARGS__)
// #define tprintf(...) while (0)

// Trace printf for debugging
// #define ttprintf(...) printf(__VA_ARGS__)
#define ttprintf(...) while (0)

volatile static uint32_t sum = 0;

unsigned __attribute__((noinline)) static_schedule(void) {
    static double *data_x, *data_y, data_a;

    data_x = snrt_l1alloc(sizeof(double) * AXPY_N);
    data_y = snrt_l1alloc(sizeof(double) * AXPY_N);

    // Init data
    data_a = 10.0;
    for (unsigned i = 0; i < AXPY_N; i++) {
        data_x[i] = (double)(i);
        data_y[i] = (double)(i + 1);
    }

    // compute
#pragma omp parallel firstprivate(data_a, data_x, data_y)
    {
        // DM, rep, bound, stride, data
        __builtin_ssr_setup_1d_r(0, 0, AXPY_N / NUMTHREADS - 1, sizeof(double),
                                 &data_x[AXPY_N / 8 * omp_get_thread_num()]);
        __builtin_ssr_setup_1d_r(1, 0, AXPY_N / NUMTHREADS - 1, sizeof(double),
                                 &data_y[AXPY_N / 8 * omp_get_thread_num()]);
        __builtin_ssr_setup_1d_w(2, 0, AXPY_N / NUMTHREADS - 1, sizeof(double),
                                 &data_y[AXPY_N / 8 * omp_get_thread_num()]);
        __builtin_ssr_enable();
#pragma omp for schedule(static)
        for (unsigned i = 0; i < AXPY_N; i++) {
            // data_y[i] = data_a * data_x[i] + data_y[i];
            // data_y[i] = data_a * __builtin_ssr_pop(0) + __builtin_ssr_pop(1);
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

#define DATASIZE 4 * 1024
#define TILESIZE (DATASIZE / 4)
#define NTHREADS 8
#include "data.h"

unsigned __attribute__((noinline)) double_buffering(void) {
    static double *bufx, *bufy, *x, *y;
    static double a;

    bufx = snrt_l1alloc(sizeof(double) * 2 * TILESIZE);
    bufy = snrt_l1alloc(sizeof(double) * 2 * TILESIZE);
    x = axpy_4096_x;
    y = axpy_4096_y;
    a = axpy_4096_a;

#pragma omp parallel firstprivate(bufx, bufy, x, y, a)
    {
        int tile;
        int thread_id = omp_get_thread_num();

        // first copy-in
        if (thread_id == 0) {
            ttprintf("copy-in t: %d\n", 0);
            dm_memcpy_async((void *)bufx, (void *)x, sizeof(double) * TILESIZE);
            dm_memcpy_async((void *)bufy, (void *)y, sizeof(double) * TILESIZE);
            dm_wait();
        }

#pragma omp barrier

        for (tile = 0; tile < DATASIZE; tile += TILESIZE) {
            // copy
            if (thread_id == 0) {
                // copy-out
                if (tile > 0) {
                    ttprintf("copy-out t: %d\n", tile);
                    dm_memcpy_async(
                        (void *)&x[tile - TILESIZE],
                        (void *)&bufx[TILESIZE * ((tile / TILESIZE + 1) % 2)],
                        sizeof(double) * TILESIZE);
                }
                // copy-in
                if (tile < DATASIZE - TILESIZE) {
                    ttprintf("copy-in t: %d\n", tile);
                    dm_memcpy_async(
                        (void *)&bufx[TILESIZE * ((tile / TILESIZE + 1) % 2)],
                        (void *)&x[tile + TILESIZE], sizeof(double) * TILESIZE);
                    dm_memcpy_async(
                        (void *)&bufy[TILESIZE * ((tile / TILESIZE + 1) % 2)],
                        (void *)&y[tile + TILESIZE], sizeof(double) * TILESIZE);
                }
                dm_start();
            }

            // compute
            // if (thread_id == 0)
            //     for (int i = 0; i < TILESIZE; ++i)
            //         tprintf("  %3d x %3.2f y %3.2f\n", i,
            //                 bufx[TILESIZE * ((tile / TILESIZE) % 2) + i],
            //                 bufy[TILESIZE * ((tile / TILESIZE) % 2) + i]);
            __builtin_ssr_setup_1d_r(0, 0, TILESIZE / NTHREADS - 1,
                                     sizeof(double),
                                     &bufx[TILESIZE * ((tile / TILESIZE) % 2) +
                                           thread_id * TILESIZE / NTHREADS]);
            __builtin_ssr_setup_1d_r(1, 0, TILESIZE / NTHREADS - 1,
                                     sizeof(double),
                                     &bufy[TILESIZE * ((tile / TILESIZE) % 2) +
                                           thread_id * TILESIZE / NTHREADS]);
            __builtin_ssr_setup_1d_w(2, 0, TILESIZE / NTHREADS - 1,
                                     sizeof(double),
                                     &bufx[TILESIZE * ((tile / TILESIZE) % 2) +
                                           thread_id * TILESIZE / NTHREADS]);

            __builtin_ssr_enable();
            asm volatile(
                // Computation
                "frep.o %[ldec], 1, 0, 0b0000   \n"
                "fmadd.d    ft2, %[a], ft0, ft1  \n" ::[a] "fr"(a),
                [ ldec ] "r"(TILESIZE / NTHREADS - 1)
                : "memory", "ft0", "ft1", "ft2");
            __builtin_ssr_barrier(2);
            __builtin_ssr_disable();

            // copy barrier
            if (thread_id == 0) dm_wait();

#pragma omp barrier
        }

        // last copy-out
        if (thread_id == 0) {
            dm_memcpy_async(
                (void *)&x[tile - TILESIZE],
                (void *)&bufx[TILESIZE * ((tile / TILESIZE + 1) % 2)],
                sizeof(double) * TILESIZE);
            dm_wait();
        }
    }

    // Verify result
    // double mse = 0.0, gold;
    // for (int i = 0; i < DATASIZE; ++i) {
    //     gold = axpy_4096_g[i];
    //     mse += (gold - x[i]) * (gold - x[i]);
    // }
    // mse = mse * 1.0 * (1.0 / (double)(DATASIZE));
    // tprintf("mse = %f\n", mse);
    // if (mse > 0.0001) return 1;

    return 0;
}

int main() {
    unsigned core_idx = snrt_cluster_core_idx();
    unsigned core_num = snrt_cluster_core_num();
    unsigned err = 0;

    __snrt_omp_bootstrap(core_idx);

    tprintf("Static schedule test\n");
    err |= static_schedule() << 0;
    OMP_PROF(omp_print_prof());

    tprintf("Launch overhead test\n");
    err |= paralell_section() << 1;
    OMP_PROF(omp_print_prof());

    tprintf("Double buffering test\n");
    err |= double_buffering() << 2;
    OMP_PROF(omp_print_prof());

    // exit
    __snrt_omp_destroy(core_idx);
    return err;
}
