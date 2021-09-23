// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#include "snrt.h"

/**
 * @brief Initialize the event unit
 */
void eu_init(void);

/**
 * @brief send all workers in loop to exit()
 * @param core_idx cluster-local core index
 */
void eu_exit(uint32_t core_idx);

/**
 * @brief Enter the event unit loop, never exits
 *
 * @param cluster_core_idx cluster-local core index
 */
void eu_event_loop(uint32_t cluster_core_idx);

/**
 * @brief Set function to execute by `nthreads` number of threads
 * @details
 *
 * @param fn pointer to worker function to be executed
 * @param data pointer to function arguments
 * @param argc number of elements in data
 * @param nthreads number of threads that have to execute this event
 */
int eu_dispatch_push(void (*fn)(void *, uint32_t), uint32_t argc, void *data,
                     uint32_t nthreads);

/**
 * @brief wait for all workers to idle
 * @param core_idx cluster-local core index
 */
void eu_run_empty(uint32_t core_idx);

/**
 * @brief Debugging info to printf
 * @details
 */
void eu_print_status();

/**
 * @brief Acquires the event unit mutex, exits only on success
 */
void eu_mutex_lock();

/**
 * @brief Releases the acquired mutex
 */
void eu_mutex_release();

/**
 * Getters
 */
uint32_t eu_get_workers_in_loop();
uint32_t eu_get_workers_in_wfi();

//================================================================================
// debug
//================================================================================

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
