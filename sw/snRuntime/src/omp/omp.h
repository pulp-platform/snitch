// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#include "eu.h"
#include "kmp.h"

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
// Macros
//================================================================================
#ifdef OMPSTATIC_NUMTHREADS
#define _OMP_T const omp_t
#define _OMP_TEAM_T const omp_team_t
#else
#define _OMP_T omp_t
#define _OMP_TEAM_T omp_team_t
#endif

/**
 * @brief Bootstrap macro for openmp applications
 */
#define __snrt_omp_bootstrap(core_idx)     \
    if (snrt_omp_bootstrap(core_idx)) do { \
            snrt_cluster_hw_barrier();     \
            return 0;                      \
    } while (0)

/**
 * @brief Destroy an OpenMP session so all cores exit cleanly
 */
#define __snrt_omp_destroy(core_idx) \
    eu_exit(core_idx);               \
    dm_exit();                       \
    snrt_cluster_hw_barrier();

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
    snrt_barrier_t *kmpc_barrier;
    /**
     * @brief Usually the arguments passed to __kmpc_fork_call would do a malloc
     * with the amount of arguments passed. This is too slow for our case and
     * thus we reserve a chunk of arguments in TCDM and use it. This limits the
     * maximum number of arguments
     */
    _kmp_ptr32 *kmpc_args;
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

void omp_print_prof(void);
#ifdef OPENMP_PROFILE
extern omp_prof_t *omp_prof;
#endif

//================================================================================
// inlines
//================================================================================

#ifndef OMPSTATIC_NUMTHREADS
static inline omp_t *omp_getData() { return (omp_t *)omp_p; }
static inline omp_team_t *omp_get_team(omp_t *_this) {
    return &_this->plainTeam;
}
#else
static inline const omp_t *omp_getData() { return &omp_p; }
static inline const omp_team_t *omp_get_team(const omp_t *_this) {
    return &_this->plainTeam;
}
#endif

static inline unsigned omp_get_thread_num(void) {
    return snrt_cluster_core_idx();
}

static inline void parallelRegion(int32_t argc, void *data,
                                  void (*fn)(void *, uint32_t),
                                  int num_threads) {
#ifndef OMPSTATIC_NUMTHREADS
    omp_p->plainTeam.nbThreads = num_threads;
#endif

    OMP_PRINTF(10, "num_threads=%d nbThreads=%d omp_p->numThreads=%d\n",
               num_threads, omp_p->plainTeam.nbThreads, omp_p->numThreads);

    // Now that the team is ready, wake up slaves
    (void)eu_dispatch_push(fn, argc, data, num_threads);

    eu_run_empty(snrt_cluster_core_idx());
}
