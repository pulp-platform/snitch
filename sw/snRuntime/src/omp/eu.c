// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "eu.h"

#include <stdlib.h>

#include "printf.h"
#include "snrt.h"

typedef struct {
    void (*fn)(void *, uint32_t);  // points to microtask wrapper
    void *data;
    uint32_t argc;
    uint32_t nthreads;
    uint32_t fini_count;
} event_t;
volatile event_t evt;

volatile static uint32_t workers_in_loop;
static uint32_t exit_flag;
static volatile uint32_t workers_mutex;

void eu_init(void) {
    workers_mutex = 0;
    workers_in_loop = 0;
    exit_flag = 0;
}

/**
 * @brief send all workers in loop to exit()
 * @details
 */
void eu_exit(uint32_t core_idx) {
    // make sure queue is empty
    eu_run_empty(core_idx);
    // set exit flag and wake cores
    exit_flag = 1;
    for (uint32_t i = 0; i < snrt_cluster_compute_core_num(); ++i) {
        snrt_int_sw_set(snrt_cluster_core_base_hartid() + i);
    }
}

/**
 * @brief Return the number of workers currently present in the event loop
 */
uint32_t eu_get_workers_in_loop() {
    return __atomic_load_n(&workers_in_loop, __ATOMIC_RELAXED);
}

/**
 * @brief Print event unit status
 *
 */
void eu_print_status(void) {
    EU_PRINTF(0, "workers_in_loop=%d\n", workers_in_loop);
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
    __atomic_add_fetch(&workers_in_loop, 1, __ATOMIC_RELAXED);
    // enable software interrupts
    snrt_interrupt_enable(IRQ_M_SOFT);

    EU_PRINTF(0, "#%d entered event loop\n", core_idx);

    while (1) {
        // check for exit
        if (exit_flag) {
            // printf("eu: exit\n");
            snrt_interrupt_disable(IRQ_M_SOFT);
            return;
        }

        if (core_idx < evt.nthreads) {
            // make a local copy of nthreads to sync after work since the master
            // hart will reset evt.nthreads as soon as all workers finished
            // which might cause a race condition
            nthds = evt.nthreads;
            EU_PRINTF(0, "run fn @ %#x (arg 0 = %#x)\n", evt.fn,
                      ((uint32_t *)evt.data)[0]);
            // call
            evt.fn(evt.data, evt.argc);
            __atomic_add_fetch(&evt.fini_count, 1, __ATOMIC_RELAXED);
            // explicit barrier
            do {
                scratch = __atomic_load_n(&evt.fini_count, __ATOMIC_RELAXED);
            } while (evt.fini_count != nthds);
        } else {
            // enter wait for interrupt
            do {
                sntr_wfi();
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
int eu_dispatch_push(void (*fn)(void *, uint32_t), uint32_t argc, void *data,
                     uint32_t nthreads) {
    // fill queue
    evt.fn = fn;
    evt.data = data;
    evt.argc = argc;
    evt.nthreads = nthreads;
    evt.fini_count = 0;

    EU_PRINTF(10, "eu_dispatch_push success, workers %d in loop %d\n", nthreads,
              workers_in_loop);

    return 0;
}

/**
 * @brief supervisor core enters this loop to empty the event queue
 * @details
 */
void eu_run_empty(uint32_t core_idx) {
    unsigned nfini;
    if (!evt.nthreads) return;
    EU_PRINTF(10, "eu_run_empty enter: q size %d\n", evt.nthreads);

    // wake all worker cores
    for (uint32_t i = 0; i < snrt_cluster_compute_core_num(); ++i) {
        snrt_int_sw_set(snrt_cluster_core_base_hartid() + i);
    }

    // Am i also part of the team?
    if (core_idx < evt.nthreads) {
        // call
        EU_PRINTF(0, "run fn @ %#x (arg 0 = %#x)\n", evt.fn,
                  ((uint32_t *)evt.data)[0]);
        evt.fn(evt.data, evt.argc);
    }

    // wait for queue to be empty
    do {
        nfini = __atomic_load_n(&evt.fini_count, __ATOMIC_RELAXED);
    } while (nfini != evt.nthreads - 1);
    // stop workers from re-executing the task
    evt.nthreads = 0;
    __atomic_add_fetch(&evt.fini_count, 1, __ATOMIC_RELAXED);

    EU_PRINTF(10, "eu_run_empty exit\n");
}

/**
 * @brief Lock the event unit mutex
 */
inline void eu_mutex_lock(void) { snrt_mutex_lock(&workers_mutex); }

/**
 * @brief Free the event unit mutex
 */
inline void eu_mutex_release(void) { snrt_mutex_release(&workers_mutex); }
