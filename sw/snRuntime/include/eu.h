// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#include "snrt.h"

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
extern __thread volatile eu_t *eu_p;

/**
 * @brief Initialize the event unit
 *
 * @return eu_t* pointer to initialized event unit struct
 */
eu_t *eu_init(void);

/**
 * @brief send all workers in loop to exit()
 * @param core_idx cluster-local core index
 */
void eu_exit(eu_t *_this, uint32_t core_idx);

/**
 * @brief Enter the event unit loop, never exits
 *
 * @param core_idx cluster-local core index
 */
void eu_event_loop(eu_t *_this, uint32_t core_idx);

/**
 * @brief Set function to execute by `nthreads` number of threads
 * @details
 *
 * @param fn pointer to worker function to be executed
 * @param data pointer to function arguments
 * @param argc number of elements in data
 * @param nthreads number of threads that have to execute this event
 */
int eu_dispatch_push(eu_t *_this, void (*fn)(void *, uint32_t), uint32_t argc,
                     void *data, uint32_t nthreads);

/**
 * @brief wait for all workers to idle
 * @param core_idx cluster-local core index
 */
void eu_run_empty(eu_t *_this, uint32_t core_idx);

/**
 * @brief Debugging info to printf
 * @details
 */
void eu_print_status(eu_t *_this);

/**
 * @brief Acquires the event unit mutex, exits only on success
 */
void eu_mutex_lock(eu_t *_this);

/**
 * @brief Releases the acquired mutex
 */
void eu_mutex_release(eu_t *_this);

/**
 * Getters
 */
uint32_t eu_get_workers_in_loop(eu_t *_this);

////////////////////////////////////////////////////////////////////////////////
// debug
////////////////////////////////////////////////////////////////////////////////

#ifdef EU_DEBUG_LEVEL
#include "printf.h"
#define _EU_PRINTF(...)             \
    if (1) {                        \
        printf("[eu] "__VA_ARGS__); \
    }
#define EU_PRINTF(d, ...)        \
    if (EU_DEBUG_LEVEL >= d) {   \
        _EU_PRINTF(__VA_ARGS__); \
    }
#else
#define EU_PRINTF(d, ...)
#endif
