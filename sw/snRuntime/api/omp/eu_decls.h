// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

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

/**
 * @brief Initialize the event unit
 */
inline void eu_init(void);

/**
 * @brief send all workers in loop to exit()
 * @param core_idx cluster-local core index
 */
inline void eu_exit(uint32_t core_idx);

/**
 * @brief Enter the event unit loop, never exits
 *
 * @param cluster_core_idx cluster-local core index
 */
inline void eu_event_loop(uint32_t cluster_core_idx);

/**
 * @brief Set function to execute by `nthreads` number of threads
 * @details
 *
 * @param fn pointer to worker function to be executed
 * @param data pointer to function arguments
 * @param argc number of elements in data
 * @param nthreads number of threads that have to execute this event
 */
inline int eu_dispatch_push(void (*fn)(void *, uint32_t), uint32_t argc,
                            void *data, uint32_t nthreads);

/**
 * @brief wait for all workers to idle
 * @param core_idx cluster-local core index
 */
inline void eu_run_empty(uint32_t core_idx);

/**
 * @brief Debugging info to printf
 * @details
 */
inline void eu_print_status();
