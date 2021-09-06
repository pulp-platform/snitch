// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "omp.h"

#include "snrt.h"

#ifndef OMP_STATIC
omp_t ompData;
#else
extern const omp_t ompData;
#endif

static inline void initTeam(omp_t *_this, omp_team_t *team) {}

void omp_init(void) {
    omp_t *_this = &ompData;

#ifndef OMP_STATIC
    unsigned int nbCores = snrt_cluster_compute_core_num();
    int coreMask = (1 << nbCores) - 1;
    _this->coreMask = coreMask;
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

    OMP_PRINTF(10, "omp_init coreMask=%#x numThreads=%d maxThreads=%d\n",
               _this->coreMask, _this->numThreads, _this->maxThreads);
}

void partialParallelRegion(int32_t argc, void *data,
                           void (*fn)(void *, uint32_t), int num_threads) {
    // int coreMask = ompData.coreMask;
    // unsigned int coreSet = (1<<num_threads)-1;
    // int nbCores = ompData.plainTeam.nbThreads;

#ifndef OMP_STATIC
    ompData.plainTeam.nbThreads = num_threads;
#endif

    OMP_PRINTF(10, "num_threads=%d nbThreads=%d ompData.numThreads=%d\n",
               num_threads, ompData.plainTeam.nbThreads, ompData.numThreads);
    parallelRegionExec(argc, data, fn, num_threads);
}
