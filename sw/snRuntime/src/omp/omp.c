// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "omp.h"

#include "snrt.h"

#ifndef OMP_STATIC
__thread omp_t volatile *omp_p;
static omp_t *volatile omp_p_global;
#else
const omp_t omp_p = {
    .plainTeam = {.nbThreads = OMPSTATIC_NUMTHREADS},
    .numThreads = OMPSTATIC_NUMTHREADS,
    .maxThreads = OMPSTATIC_NUMTHREADS,
};
#endif

static inline void initTeam(omp_t *_this, omp_team_t *team) {}

void omp_init(void) {
    if (snrt_cluster_core_idx() == 0) {
        omp_p = (omp_t *)snrt_l1alloc(sizeof(omp_t));

#ifndef OMP_STATIC
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
#endif
        omp_p_global = omp_p;
    } else {
        while (!omp_p_global)
            ;
        omp_p = omp_p_global;
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
        while (eu_get_workers_in_loop() !=
               (snrt_cluster_compute_core_num() - 1))
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
#ifndef OMP_STATIC
    omp_p->plainTeam.nbThreads = num_threads;
#endif

    OMP_PRINTF(10, "num_threads=%d nbThreads=%d omp_p->numThreads=%d\n",
               num_threads, omp_p->plainTeam.nbThreads, omp_p->numThreads);
    parallelRegionExec(argc, data, fn, num_threads);
}
