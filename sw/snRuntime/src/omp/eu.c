// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "eu.h"

#include <stdlib.h>

#include "printf.h"
#include "snrt.h"

//================================================================================
// Settings
//================================================================================
/**
 * @brief Define EU_USE_GLOBAL_CLINT to use the cluster-shared CLINT based SW
 * interrupt system for synchronization. If not defined, the harts use the
 * cluster-local CLINT to syncrhonize which is faster but only works for
 * cluster-local synchronization which is sufficient at the moment since the
 * OpenMP runtime is single cluster only.
 *
 */
// #define EU_USE_GLOBAL_CLINT

//================================================================================
// Types
//================================================================================

typedef struct {
    uint32_t workers_in_loop;
    uint32_t exit_flag;
    uint32_t workers_mutex;
    uint32_t workers_wfi;
    struct {
        void (*fn)(void *, uint32_t);  // points to microtask wrapper
        void *data;
        uint32_t argc;
        uint32_t nthreads;
        uint32_t fini_count;
    } e;
} eu_t;

//================================================================================
// data
//================================================================================
/**
 * @brief Pointer to the event unit struct only initialized after call to
 * eu_init for main thread and call to eu_event_loop for worker threads
 *
 */
__thread volatile eu_t *eu_p;

/**
 * @brief Pointer to where the DM struct in TCDM is located
 *
 */
static volatile eu_t *volatile eu_p_global;

//================================================================================
// prototypes
//================================================================================
static void wake_workers(void);
static void worker_wfi(uint32_t cluster_core_idx);
static void wait_worker_wfi(void);

//================================================================================
// public
//================================================================================
void eu_init(void) {
    if (snrt_cluster_core_idx() == 0) {
        // Allocate the eu struct in L1 for fast access
        eu_p = snrt_l1alloc(sizeof(eu_t));
        snrt_memset((void *)eu_p, 0, sizeof(eu_t));
        // store copy of eu_p on shared memory
        eu_p_global = eu_p;
    } else {
        while (!eu_p_global)
            ;
        eu_p = eu_p_global;
    }
}

/**
 * @brief send all workers in loop to exit()
 * @details
 */
void eu_exit(uint32_t core_idx) {
    // make sure queue is empty
    if (!eu_p->e.nthreads) eu_run_empty(core_idx);
    // set exit flag and wake cores
    wait_worker_wfi();
    eu_p->exit_flag = 1;
    wake_workers();
}

/**
 * @brief Return the number of workers currently present in the event loop
 */
uint32_t eu_get_workers_in_loop() {
    return __atomic_load_n(&eu_p->workers_in_loop, __ATOMIC_RELAXED);
}

/**
 * @brief Return the number of workers currently in the loop and waiting for
 * interrupt
 */
uint32_t eu_get_workers_in_wfi() {
    return __atomic_load_n(&eu_p->workers_wfi, __ATOMIC_RELAXED);
}

/**
 * @brief Print event unit status
 *
 */
void eu_print_status() {
    EU_PRINTF(0, "workers_in_loop=%d\n", eu_p->workers_in_loop);
}

/**
 * @brief Main loop of the event unit
 *
 * @param cluster_core_idx local core index of the entering thread
 */
void eu_event_loop(uint32_t cluster_core_idx) {
    uint32_t scratch;
    uint32_t nthds;

    // count number of workers in loop
    __atomic_add_fetch(&eu_p->workers_in_loop, 1, __ATOMIC_RELAXED);

    // enable software interrupts
#ifdef EU_USE_GLOBAL_CLINT
    snrt_interrupt_enable(IRQ_M_SOFT);
#else
    snrt_interrupt_enable(IRQ_M_CLUSTER);
#endif

    EU_PRINTF(0, "#%d entered event loop\n", cluster_core_idx);

    while (1) {
        // check for exit
        if (eu_p->exit_flag) {
#ifdef EU_USE_GLOBAL_CLINT
            snrt_interrupt_disable(IRQ_M_SOFT);
#else
            snrt_interrupt_enable(IRQ_M_CLUSTER);
#endif
            return;
        }

        if (cluster_core_idx < eu_p->e.nthreads) {
            // make a local copy of nthreads to sync after work since the master
            // hart will reset eu_p->e.nthreads as soon as all workers finished
            // which might cause a race condition
            nthds = eu_p->e.nthreads;
            EU_PRINTF(0, "run fn @ %#x (arg 0 = %#x)\n", eu_p->e.fn,
                      ((uint32_t *)eu_p->e.data)[0]);
            // call
            eu_p->e.fn(eu_p->e.data, eu_p->e.argc);
        }

        // enter wait for interrupt
        __atomic_add_fetch(&eu_p->e.fini_count, 1, __ATOMIC_RELAXED);
        worker_wfi(cluster_core_idx);
    }
}

/**
 * @brief Add a task to the event unit's queue
 *
 * @param fn function pointer
 * @param argc number of arguments passed to the function
 * @param data Pointer to the arguments
 * @param nthreads Number of threads that shall run the task
 * @return int 0
 */
int eu_dispatch_push(void (*fn)(void *, uint32_t), uint32_t argc, void *data,
                     uint32_t nthreads) {
    // wait for workers to be in wfi before manipulating the event struct
    wait_worker_wfi();

    // fill queue
    eu_p->e.fn = fn;
    eu_p->e.data = data;
    eu_p->e.argc = argc;
    eu_p->e.nthreads = nthreads;

    EU_PRINTF(10, "eu_dispatch_push success, workers %d in loop %d\n", nthreads,
              eu_p->workers_in_loop);

    return 0;
}

/**
 * @brief supervisor core enters this loop to empty the event queue
 * @details
 */
void eu_run_empty(uint32_t core_idx) {
    unsigned nfini, scratch;
    scratch = eu_p->e.nthreads;
    if (!scratch) return;
    EU_PRINTF(10, "eu_run_empty enter: q size %d\n", eu_p->e.nthreads);

    eu_p->e.fini_count = 0;
    if (scratch > 1) wake_workers();

    // Am i also part of the team?
    if (core_idx < eu_p->e.nthreads) {
        // call
        EU_PRINTF(0, "run fn @ %#x (arg 0 = %#x)\n", eu_p->e.fn,
                  ((uint32_t *)eu_p->e.data)[0]);
        eu_p->e.fn(eu_p->e.data, eu_p->e.argc);
    }

    // wait for queue to be empty
    if (scratch > 1) {
        scratch = eu_get_workers_in_loop();
        while (__atomic_load_n(&eu_p->e.fini_count, __ATOMIC_RELAXED) !=
               scratch)
            ;
    }

    // stop workers from re-executing the task
    eu_p->e.nthreads = 0;

    EU_PRINTF(10, "eu_run_empty exit\n");
}

/**
 * @brief Lock the event unit mutex
 */
inline void eu_mutex_lock() { snrt_mutex_lock(&eu_p->workers_mutex); }

/**
 * @brief Free the event unit mutex
 */
inline void eu_mutex_release() { snrt_mutex_release(&eu_p->workers_mutex); }

//================================================================================
// private
//================================================================================

static void wait_worker_wfi(void) {
    uint32_t scratch = eu_p->workers_in_loop;
    while (__atomic_load_n(&eu_p->workers_wfi, __ATOMIC_RELAXED) != scratch)
        ;
}

/**
 * @brief When using the CLINT as wakeup
 *
 */
#ifdef EU_USE_GLOBAL_CLINT

static void wake_workers(void) {
#ifdef OMPSTATIC_NUMTHREADS
#define WAKE_MASK (((1 << OMPSTATIC_NUMTHREADS) - 1) & ~0x1)
    // Fast wake-up for static number of worker threads
    uint32_t basehart = snrt_cluster_core_base_hartid();
    if ((basehart % 32) + OMPSTATIC_NUMTHREADS > 32) {
        // wake-up is split over two CLINT registers
        snrt_int_clint_set(basehart / 32, WAKE_MASK << (basehart % 32));
        snrt_int_clint_set(basehart / 32 + 1,
                           WAKE_MASK >> (32 - basehart % 32));
    } else {
        snrt_int_clint_set(basehart / 32, WAKE_MASK << (basehart % 32));
    }
    const uint32_t mask = OMPSTATIC_NUMTHREADS - 1;
#else

    // wake all worker cores except the main thread
    uint32_t numcores = snrt_cluster_compute_core_num(),
             basehart = snrt_cluster_core_base_hartid();
    uint32_t mask = 0, hart = 1;
    for (; hart < numcores; ++hart) {
        mask |= 1 << (basehart + hart);
        if ((basehart + hart + 1) % 32 == 0) {
            snrt_int_clint_set((basehart + hart) / 32, mask);
            mask = 0;
        }
    }
    if (mask) snrt_int_clint_set((basehart + hart) / 32, mask);
#endif
}

static void worker_wfi(uint32_t cluster_core_idx) {
    __atomic_add_fetch(&eu_p->workers_wfi, 1, __ATOMIC_RELAXED);
    snrt_int_sw_poll();
    __atomic_add_fetch(&eu_p->workers_wfi, -1, __ATOMIC_RELAXED);
}

/**
 * @brief If we use the wake-up register to wake the worker cores
 *
 */
#else  // #ifdef EU_USE_GLOBAL_CLINT

static void wake_workers(void) {
    // Guard to wake only if all workers are wfi
    wait_worker_wfi();
    // Wake the cluster cores. We do this with cluster relative hart IDs and do
    // not wake hart 0 since this is the main thread
    uint32_t numcores = snrt_cluster_compute_core_num();
    snrt_int_cluster_set(~0x1 & ((1 << numcores) - 1));
}
static void worker_wfi(uint32_t cluster_core_idx) {
    __atomic_add_fetch(&eu_p->workers_wfi, 1, __ATOMIC_RELAXED);
    snrt_wfi();
    snrt_int_cluster_clr(1 << cluster_core_idx);
    __atomic_add_fetch(&eu_p->workers_wfi, -1, __ATOMIC_RELAXED);
}

#endif  // #ifdef EU_USE_GLOBAL_CLINT
