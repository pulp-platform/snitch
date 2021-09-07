// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#include "eu.h"
#include "snrt.h"

typedef struct {
    char nbThreads;
#ifndef OMP_STATIC
    int loop_epoch;
    int loop_start;
    int loop_end;
    int loop_incr;
    int loop_chunk;
    int loop_is_setup;
    int core_epoch[16];  // for dynamic scheduling
#endif
} omp_team_t;

typedef struct {
    omp_team_t plainTeam;
    int numThreads;
    int maxThreads;
#ifndef OMP_STATIC
    uint32_t lastCycleCnt;
#endif
} omp_t;

#ifndef OMP_STATIC
extern omp_t ompData;
#else
extern const omp_t ompData;
#endif

////////////////////////////////////////////////////////////////////////////////
// exported
////////////////////////////////////////////////////////////////////////////////

void omp_init(void);
unsigned snrt_omp_bootstrap(uint32_t core_idx);
void partialParallelRegion(int32_t argc, void *data,
                           void (*fn)(void *, uint32_t), int num_threads);

static inline omp_t *omp_getData() { return &ompData; }

////////////////////////////////////////////////////////////////////////////////
// debug
////////////////////////////////////////////////////////////////////////////////

#ifdef OMP_DEBUG_LEVEL
#include "encoding.h"
#include "printf.h"
#define _OMP_PRINTF(...)             \
    if (1) {                         \
        printf("[omp] "__VA_ARGS__); \
    }
#define OMP_PRINTF(d, ...)        \
    if (OMP_DEBUG_LEVEL >= d) {   \
        _OMP_PRINTF(__VA_ARGS__); \
    }
#else
#define OMP_PRINTF(d, ...)
#endif

////////////////////////////////////////////////////////////////////////////////
// inlines
////////////////////////////////////////////////////////////////////////////////

static inline unsigned omp_get_thread_num(void) {
    return snrt_cluster_core_idx();
}

static inline omp_team_t *omp_get_team(omp_t *_this) {
    return &_this->plainTeam;
}

static inline void __attribute__((always_inline))
parallelRegionExec(int32_t argc, void *data, void (*fn)(void *, uint32_t),
                   int num_threads) {
    // pulp_timer_t start_time, stop_time;

    // Now that the team is ready, wake up slaves
    (void)eu_dispatch_push(eu_p, fn, argc, data, num_threads);

    // Team execution
    // perfParallelEnter();

    // enter self
    // fn(data, argc);

    // start_time = pulp_get_timer();
    // reset_peripheral_counters();
    // start_peripheral_counters();
    eu_run_empty(eu_p, snrt_cluster_core_idx());
    // stop_time = pulp_get_timer();
    // stop_peripheral_counters();
    // OMP_PRINTF(0, "cycles=%d\n",stop_time-start_time);
    // omp_getData()->lastCycleCnt = stop_time-start_time;
    // perfParallelExit();

    // Execute the final barrier to wait until the slaves have finished the team
    // execution doBarrier((void *)0);
}

static inline void __attribute__((always_inline))
parallelRegion(int32_t argc, void *data, void (*fn)(void *, uint32_t),
               int num_threads) {
    partialParallelRegion(argc, data, fn, num_threads);

    // if (num_threads <= omp_getData()->maxThreads) {
    //   // We differentiate plain team and partial teams to put more
    //   optimizations on plain teams
    //   // as they are the most used
    // } else {
    //   printf("FATAL: unimplemented\n");
    //   // TODO: implement
    //   // partialParallelRegion(fn, data, num_threads);
    // }
}
