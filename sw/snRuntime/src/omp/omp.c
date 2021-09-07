// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "omp.h"

#include "snrt.h"

#ifndef OMP_STATIC
omp_t ompData;
#else
const omp_t ompData = {
    .plainTeam = {.nbThreads = OMPSTATIC_NUMTHREADS},
    .numThreads = OMPSTATIC_NUMTHREADS,
    .maxThreads = OMPSTATIC_NUMTHREADS,
};
#endif

static inline void initTeam(omp_t *_this, omp_team_t *team) {}

void omp_init(void) {
    omp_t *_this = &ompData;

#ifndef OMP_STATIC
    unsigned int nbCores = snrt_cluster_compute_core_num();
    _this->numThreads = nbCores;
    _this->maxThreads = nbCores;

    _this->plainTeam.nbThreads = nbCores;
    _this->plainTeam.loop_epoch = 0;
    _this->plainTeam.loop_is_setup = 0;

    // _this->plainTeam.loop_start;
    // _this->plainTeam.loop_end;
    // _this->plainTeam.loop_incr;
    // _this->plainTeam.loop_chunk;
    for (int i = 0; i < sizeof(_this->plainTeam.core_epoch) /
                            sizeof(_this->plainTeam.core_epoch[0]);
         i++)
        _this->plainTeam.core_epoch[i] = 0;

    initTeam(_this, &_this->plainTeam);
#endif

    OMP_PRINTF(10, "omp_init numThreads=%d maxThreads=%d\n", _this->numThreads,
               _this->maxThreads);
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
    static eu_t *eu;
    if (core_idx == 0) {
        // master hart initializes event unit and runtime
        eu = eu_init();
        omp_init();
        snrt_cluster_hw_barrier();
        while (eu_get_workers_in_loop(eu_p) !=
               (snrt_cluster_compute_core_num() - 1))
            ;
        return 0;
    } else if (snrt_is_dm_core()) {
        // park dm core for now
        snrt_cluster_hw_barrier();
        return 1;
    } else {
        // all worker cores enter the event queue
        snrt_cluster_hw_barrier();
        eu_event_loop(eu, core_idx);
        return 1;
    }
}

void partialParallelRegion(int32_t argc, void *data,
                           void (*fn)(void *, uint32_t), int num_threads) {
#ifndef OMP_STATIC
    ompData.plainTeam.nbThreads = num_threads;
#endif

    OMP_PRINTF(10, "num_threads=%d nbThreads=%d ompData.numThreads=%d\n",
               num_threads, ompData.plainTeam.nbThreads, ompData.numThreads);
    parallelRegionExec(argc, data, fn, num_threads);
}
