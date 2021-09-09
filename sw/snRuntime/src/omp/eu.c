// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "eu.h"

#include <stdlib.h>

#include "printf.h"
#include "snrt.h"

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
static eu_t *volatile eu_p_global;

//================================================================================
// prototypes
//================================================================================
void wake_workers(void);
void worker_wfi(void);

//================================================================================
// public
//================================================================================
void eu_init(void) {
    if (snrt_cluster_core_idx() == 0) {
        // Allocate the eu struct in L1 for fast access
        eu_p = snrt_l1alloc(sizeof(eu_t));
        snrt_memset(eu_p, 0, sizeof(eu_t));
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
    eu_run_empty(core_idx);
    // set exit flag and wake cores
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
 * @brief Print event unit status
 *
 */
void eu_print_status() {
    EU_PRINTF(0, "workers_in_loop=%d\n", eu_p->workers_in_loop);
}

/**
 * @brief Main loop of the event unit
 *
 * @param core_idx local core index of the entering thread
 */
void eu_event_loop(uint32_t core_idx) {
    uint32_t scratch;
    uint32_t nthds;

    // count number of workers in loop
    __atomic_add_fetch(&eu_p->workers_in_loop, 1, __ATOMIC_RELAXED);

    // enable software interrupts
#ifdef EU_USE_CLINT
    snrt_interrupt_enable(IRQ_M_SOFT);
#endif

    EU_PRINTF(0, "#%d entered event loop\n", core_idx);

    while (1) {
        // check for exit
        if (eu_p->exit_flag) {
#ifdef EU_USE_CLINT
            snrt_interrupt_disable(IRQ_M_SOFT);
#endif
            return;
        }

        if (core_idx < eu_p->e.nthreads) {
            // make a local copy of nthreads to sync after work since the master
            // hart will reset eu_p->e.nthreads as soon as all workers finished
            // which might cause a race condition
            nthds = eu_p->e.nthreads;
            EU_PRINTF(0, "run fn @ %#x (arg 0 = %#x)\n", eu_p->e.fn,
                      ((uint32_t *)eu_p->e.data)[0]);
            // call
            eu_p->e.fn(eu_p->e.data, eu_p->e.argc);
            __atomic_add_fetch(&eu_p->e.fini_count, 1, __ATOMIC_RELAXED);
            // explicit barrier
            while (__atomic_load_n(&eu_p->e.fini_count, __ATOMIC_RELAXED) !=
                   nthds)
                ;
        } else {
            // enter wait for interrupt
            __atomic_add_fetch(&eu_p->workers_wfi, 1, __ATOMIC_RELAXED);
            worker_wfi();
            __atomic_add_fetch(&eu_p->workers_wfi, -1, __ATOMIC_RELAXED);
        }
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
    // fill queue
    eu_p->e.fn = fn;
    eu_p->e.data = data;
    eu_p->e.argc = argc;
    eu_p->e.nthreads = nthreads;
    eu_p->e.fini_count = 0;

    EU_PRINTF(10, "eu_dispatch_push success, workers %d in loop %d\n", nthreads,
              eu_p->workers_in_loop);

    return 0;
}

/**
 * @brief supervisor core enters this loop to empty the event queue
 * @details
 */
void eu_run_empty(uint32_t core_idx) {
    unsigned nfini;
    if (!eu_p->e.nthreads) return;
    EU_PRINTF(10, "eu_run_empty enter: q size %d\n", eu_p->e.nthreads);

    wake_workers();

    // Am i also part of the team?
    if (core_idx < eu_p->e.nthreads) {
        // call
        EU_PRINTF(0, "run fn @ %#x (arg 0 = %#x)\n", eu_p->e.fn,
                  ((uint32_t *)eu_p->e.data)[0]);
        eu_p->e.fn(eu_p->e.data, eu_p->e.argc);
    }

    // wait for queue to be empty
    while (__atomic_load_n(&eu_p->e.fini_count, __ATOMIC_RELAXED) !=
           eu_p->e.nthreads - 1)
        ;
    // stop workers from re-executing the task
    eu_p->e.nthreads = 0;
    __atomic_add_fetch(&eu_p->e.fini_count, 1, __ATOMIC_RELAXED);

    // wait for all workers to be in wfi
    while (__atomic_load_n(&eu_p->workers_wfi, __ATOMIC_RELAXED) !=
           eu_p->workers_in_loop)
        ;

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

/**
 * @brief When using the CLINT as wakeup
 *
 */
#ifdef EU_USE_CLINT

void wake_workers(void) {
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

void worker_wfi(void) { snrt_int_sw_poll(); }

/**
 * @brief If we use the wake-up register to wake the worker cores
 *
 */
#else  // #ifdef EU_USE_CLINT

void wake_workers(void) {
    // Guard to wake only if all workers are wfi
    while (__atomic_load_n(&eu_p->workers_wfi, __ATOMIC_RELAXED) !=
           eu_p->workers_in_loop)
        ;
    // Wake the cluster cores. We do this with cluster relative hart IDs and do
    // not wake hart 0 since this is the main thread
    uint32_t numcores = snrt_cluster_compute_core_num();
    for (uint32_t hart = 1; hart < numcores; ++hart) snrt_wakeup(hart);
}
void worker_wfi(void) { sntr_wfi(); }

#endif  // #ifdef EU_USE_CLINT
