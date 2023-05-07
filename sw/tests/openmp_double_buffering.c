// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

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
            printf("copy-in t: %d\n", 0);
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
                    printf("copy-out t: %d\n", tile);
                    dm_memcpy_async(
                        (void *)&x[tile - TILESIZE],
                        (void *)&bufx[TILESIZE * ((tile / TILESIZE + 1) % 2)],
                        sizeof(double) * TILESIZE);
                }
                // copy-in
                if (tile < DATASIZE - TILESIZE) {
                    printf("copy-in t: %d\n", tile);
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
            //         printf("  %3d x %3.2f y %3.2f\n", i,
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
    // printf("mse = %f\n", mse);
    // if (mse > 0.0001) return 1;

    return 0;
}

int main() {
    unsigned core_idx = snrt_cluster_core_idx();
    unsigned core_num = snrt_cluster_core_num();
    unsigned err = 0;

    // Only core 0 executes the statements below this function
    __snrt_omp_bootstrap(core_idx);

    printf("Double buffering test\n");
    err = double_buffering();
    omp_print_prof();

    // exit
    __snrt_omp_destroy(core_idx);
    return err;
}
