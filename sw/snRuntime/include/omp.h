// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#include "eu.h"
#include "snrt.h"

//================================================================================
// debug
//================================================================================
#define OPENMP_PROFILE

#ifdef OPENMP_PROFILE
#define OMP_PROF(X) \
    do {            \
        { X; }      \
    } while (0)
#else
#define OMP_PROF(X) \
    do {            \
    } while (0)
#endif

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

//================================================================================
// types
//================================================================================

typedef struct {
    char nbThreads;
#ifndef OMPSTATIC_NUMTHREADS
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
#ifndef OMPSTATIC_NUMTHREADS
    omp_team_t plainTeam;
    int numThreads;
    int maxThreads;
#else
    const omp_team_t plainTeam;
    const int numThreads;
    const int maxThreads;
#endif
    /**
     * @brief Pointer to the barrier register used for synchronization eg with
     * #pragma omp barrier
     *
     */
    uint32_t *kmpc_barrier;
} omp_t;

#ifdef OPENMP_PROFILE
typedef struct {
    uint32_t fork_oh;
} omp_prof_t;
extern omp_prof_t *omp_prof;
#endif

#ifndef OMPSTATIC_NUMTHREADS
extern __thread omp_t volatile *omp_p;
#else
extern omp_t omp_p;
#endif

//================================================================================
// exported
//================================================================================

void omp_init(void);
unsigned snrt_omp_bootstrap(uint32_t core_idx);
void partialParallelRegion(int32_t argc, void *data,
                           void (*fn)(void *, uint32_t), int num_threads);

static inline omp_t *omp_getData() {
#ifndef OMPSTATIC_NUMTHREADS
    return omp_p;
#else
    return &omp_p;
#endif
}

#ifdef OPENMP_PROFILE
void omp_print_prof(void);
#endif

//================================================================================
// inlines
//================================================================================

static inline unsigned omp_get_thread_num(void) {
    return snrt_cluster_core_idx();
}

static inline omp_team_t *omp_get_team(omp_t *_this) {
    return &_this->plainTeam;
}

static inline void __attribute__((always_inline))
parallelRegionExec(int32_t argc, void *data, void (*fn)(void *, uint32_t),
                   int num_threads) {
    // Now that the team is ready, wake up slaves
    (void)eu_dispatch_push(fn, argc, data, num_threads);

    eu_run_empty(snrt_cluster_core_idx());
}

static inline void __attribute__((always_inline))
parallelRegion(int32_t argc, void *data, void (*fn)(void *, uint32_t),
               int num_threads) {
    partialParallelRegion(argc, data, fn, num_threads);
}
