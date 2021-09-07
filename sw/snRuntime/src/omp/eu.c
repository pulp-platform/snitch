// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "eu.h"

#include <stdlib.h>

#include "printf.h"
#include "snrt.h"

/**
 * @brief Pointer to the event unit struct only initialized after call to
 * eu_init for main thread and call to eu_event_loop for worker threads
 *
 */
__thread eu_t *eu_p;

eu_t *eu_init(void) {
    // Allocate the eu struct in L1 for fast access
    eu_t *_this = snrt_l1alloc(sizeof(eu_t));
    _this->workers_mutex = 0;
    _this->workers_in_loop = 0;
    _this->exit_flag = 0;
    _this->workers_wfi = 0;
    // store copy of eu_p on tls
    eu_p = _this;
    return eu_p;
}

/**
 * @brief send all workers in loop to exit()
 * @details
 */
void eu_exit(eu_t *_this, uint32_t core_idx) {
    // make sure queue is empty
    eu_run_empty(_this, core_idx);
    // set exit flag and wake cores
    _this->exit_flag = 1;
    for (uint32_t i = 0; i < snrt_cluster_compute_core_num(); ++i) {
        snrt_int_sw_set(snrt_cluster_core_base_hartid() + i);
    }
}

/**
 * @brief Return the number of workers currently present in the event loop
 */
uint32_t eu_get_workers_in_loop(eu_t *_this) {
    return __atomic_load_n(&_this->workers_in_loop, __ATOMIC_RELAXED);
}

/**
 * @brief Print event unit status
 *
 */
void eu_print_status(eu_t *_this) {
    EU_PRINTF(0, "workers_in_loop=%d\n", _this->workers_in_loop);
}

/**
 * @brief Main loop of the event unit
 *
 * @param core_idx local core index of the entering thread
 */
void eu_event_loop(eu_t *_this, uint32_t core_idx) {
    uint32_t scratch;
    uint32_t nthds;

    // store copy of eu_p on tls
    eu_p = _this;

    // count number of workers in loop
    __atomic_add_fetch(&_this->workers_in_loop, 1, __ATOMIC_RELAXED);
    // enable software interrupts
    snrt_interrupt_enable(IRQ_M_SOFT);

    EU_PRINTF(0, "#%d entered event loop\n", core_idx);

    while (1) {
        // check for exit
        if (_this->exit_flag) {
            // printf("eu: exit\n");
            snrt_interrupt_disable(IRQ_M_SOFT);
            return;
        }

        if (core_idx < _this->e.nthreads) {
            // make a local copy of nthreads to sync after work since the master
            // hart will reset _this->e.nthreads as soon as all workers finished
            // which might cause a race condition
            nthds = _this->e.nthreads;
            EU_PRINTF(0, "run fn @ %#x (arg 0 = %#x)\n", _this->e.fn,
                      ((uint32_t *)_this->e.data)[0]);
            // call
            _this->e.fn(_this->e.data, _this->e.argc);
            __atomic_add_fetch(&_this->e.fini_count, 1, __ATOMIC_RELAXED);
            // explicit barrier
            while (__atomic_load_n(&_this->e.fini_count, __ATOMIC_RELAXED) !=
                   nthds)
                ;
        } else {
            // enter wait for interrupt
            do {
                __atomic_add_fetch(&_this->workers_wfi, 1, __ATOMIC_RELAXED);
                sntr_wfi();
                __atomic_add_fetch(&_this->workers_wfi, -1, __ATOMIC_RELAXED);
            } while (
                !snrt_int_sw_get(snrt_global_core_base_hartid() + core_idx));
            snrt_int_sw_clear(snrt_global_core_base_hartid() + core_idx);
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
int eu_dispatch_push(eu_t *_this, void (*fn)(void *, uint32_t), uint32_t argc,
                     void *data, uint32_t nthreads) {
    // fill queue
    _this->e.fn = fn;
    _this->e.data = data;
    _this->e.argc = argc;
    _this->e.nthreads = nthreads;
    _this->e.fini_count = 0;

    EU_PRINTF(10, "eu_dispatch_push success, workers %d in loop %d\n", nthreads,
              _this->workers_in_loop);

    return 0;
}

/**
 * @brief supervisor core enters this loop to empty the event queue
 * @details
 */
void eu_run_empty(eu_t *_this, uint32_t core_idx) {
    unsigned nfini;
    if (!_this->e.nthreads) return;
    EU_PRINTF(10, "eu_run_empty enter: q size %d\n", _this->e.nthreads);

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

    // Am i also part of the team?
    if (core_idx < _this->e.nthreads) {
        // call
        EU_PRINTF(0, "run fn @ %#x (arg 0 = %#x)\n", _this->e.fn,
                  ((uint32_t *)_this->e.data)[0]);
        _this->e.fn(_this->e.data, _this->e.argc);
    }

    // wait for queue to be empty
    while (__atomic_load_n(&_this->e.fini_count, __ATOMIC_RELAXED) !=
           _this->e.nthreads - 1)
        ;
    // stop workers from re-executing the task
    _this->e.nthreads = 0;
    __atomic_add_fetch(&_this->e.fini_count, 1, __ATOMIC_RELAXED);

    // wait for all workers to be in wfi
    while (__atomic_load_n(&_this->workers_wfi, __ATOMIC_RELAXED) !=
           _this->workers_in_loop)
        ;

    EU_PRINTF(10, "eu_run_empty exit\n");
}

/**
 * @brief Lock the event unit mutex
 */
inline void eu_mutex_lock(eu_t *_this) {
    snrt_mutex_lock(&_this->workers_mutex);
}

/**
 * @brief Free the event unit mutex
 */
inline void eu_mutex_release(eu_t *_this) {
    snrt_mutex_release(&_this->workers_mutex);
}
