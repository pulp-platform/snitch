// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "omp.h"

#include "dm.h"
#include "snrt.h"

//================================================================================
// settings
//================================================================================
/**
 * @brief Usually the arguments passed to __kmpc_fork_call would to a malloc
 * with the amount of arguments passed. This is too slow for our case and thus
 * we reserve a chunk of arguments in TCDM and use it. This limits the maximum
 * number of arguments
 *
 */
#define KMP_FORK_MAX_NARGS 12

//================================================================================
// data
//================================================================================
static omp_t *volatile omp_p_global;

#ifndef OMPSTATIC_NUMTHREADS
__thread omp_t volatile *omp_p;
#else
omp_t omp_p = {
    .plainTeam = {.nbThreads = OMPSTATIC_NUMTHREADS},
    .numThreads = OMPSTATIC_NUMTHREADS,
    .maxThreads = OMPSTATIC_NUMTHREADS,
};
#endif

#ifdef OMP_PROF
#include "printf.h"
omp_prof_t *omp_prof;
#endif

//================================================================================
// public
//================================================================================
static inline void initTeam(omp_t *_this, omp_team_t *team) {
    (void)_this;
    (void)team;
}

void omp_init(void) {
    if (snrt_cluster_core_idx() == 0) {
        // allocate space for kmp arguments
        kmpc_args =
            (_kmp_ptr32 *)snrt_l1alloc(sizeof(_kmp_ptr32) * KMP_FORK_MAX_NARGS);
#ifndef OMPSTATIC_NUMTHREADS
        omp_p = (omp_t *)snrt_l1alloc(sizeof(omp_t));
        unsigned int nbCores = snrt_cluster_compute_core_num();
        omp_p->numThreads = nbCores;
        omp_p->maxThreads = nbCores;

        omp_p->plainTeam.nbThreads = nbCores;
        omp_p->plainTeam.loop_epoch = 0;
        omp_p->plainTeam.loop_is_setup = 0;

        for (int i = 0; i < sizeof(omp_p->plainTeam.core_epoch) /
                                sizeof(omp_p->plainTeam.core_epoch[0]);
             i++)
            omp_p->plainTeam.core_epoch[i] = 0;

        initTeam(omp_p, &omp_p->plainTeam);
        omp_p->kmpc_barrier =
            (struct snrt_barrier *)snrt_l1alloc(sizeof(struct snrt_barrier));
        snrt_memset(omp_p->kmpc_barrier, 0, sizeof(struct snrt_barrier));
        // Exchange omp pointer with other cluster cores
        omp_p_global = omp_p;
#else
        omp_p.kmpc_barrier =
            (struct snrt_barrier *)snrt_l1alloc(sizeof(struct snrt_barrier));
        snrt_memset(omp_p.kmpc_barrier, 0, sizeof(struct snrt_barrier));
        // Exchange omp pointer with other cluster cores
        omp_p_global = &omp_p;
#endif

#ifdef OPENMP_PROFILE
        omp_prof = (omp_prof_t *)snrt_l1alloc(sizeof(omp_prof_t));
#endif

    } else {
        while (!omp_p_global)
            ;
#ifndef OMPSTATIC_NUMTHREADS
        omp_p = omp_p_global;
#endif
    }

    OMP_PRINTF(10, "omp_init numThreads=%d maxThreads=%d\n", omp_p->numThreads,
               omp_p->maxThreads);
}

/**
 * @brief Bootstrap the system for the use of the OpenMP runtime
 * Bootstrap: Core 0 inits the event unit and all other cores enter it while
 * core 0 waits for the queue to be full of workers
 * Park DM core
 *
 * Use: if(snrt_omp_bootstrap(core_idx)) return 0;
 *
 * @param core_idx cluster-local core-index
 */
unsigned __attribute__((noinline)) snrt_omp_bootstrap(uint32_t core_idx) {
    dm_init();
    eu_init();
    omp_init();
    if (core_idx == 0) {
        // master hart initializes event unit and runtime
        snrt_cluster_hw_barrier();
        while (eu_get_workers_in_wfi() != (snrt_cluster_compute_core_num() - 1))
            ;
        return 0;
    } else if (snrt_is_dm_core()) {
        // send datamover to dm_main
        snrt_cluster_hw_barrier();
        dm_main();
        return 1;
    } else {
        // all worker cores enter the event queue
        snrt_cluster_hw_barrier();
        eu_event_loop(core_idx);
        return 1;
    }
}

void partialParallelRegion(int32_t argc, void *data,
                           void (*fn)(void *, uint32_t), int num_threads) {
#ifndef OMPSTATIC_NUMTHREADS
    omp_p->plainTeam.nbThreads = num_threads;
#endif

    OMP_PRINTF(10, "num_threads=%d nbThreads=%d omp_p->numThreads=%d\n",
               num_threads, omp_p->plainTeam.nbThreads, omp_p->numThreads);
    parallelRegionExec(argc, data, fn, num_threads);
}

#ifdef OPENMP_PROFILE
void omp_print_prof(void) {
    printf("%-20s %d\n", "fork_oh", omp_prof->fork_oh);
}
#endif
