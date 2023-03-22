// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//================================================================================
// Data
//================================================================================

extern volatile uint32_t _snrt_mutex;
extern volatile uint32_t _snrt_barrier;

//================================================================================
// Mutex functions
//================================================================================

inline volatile uint32_t *snrt_mutex() { return &_snrt_mutex; }

/**
 * @brief lock a mutex, blocking
 * @details declare mutex with `static volatile uint32_t mtx = 0;`
 */
inline void snrt_mutex_acquire(volatile uint32_t *pmtx) {
    asm volatile(
        "li            t0,1          # t0 = 1\n"
        "1:\n"
        "  amoswap.w.aq  t0,t0,(%0)   # t0 = oldlock & lock = 1\n"
        "  bnez          t0,1b      # Retry if previously set)\n"
        : "+r"(pmtx)
        :
        : "t0");
}

/**
 * @brief lock a mutex, blocking
 * @details test and test-and-set (ttas) implementation of a lock.
 *          Declare mutex with `static volatile uint32_t mtx = 0;`
 */
inline void snrt_mutex_ttas_acquire(volatile uint32_t *pmtx) {
    asm volatile(
        "1:\n"
        "  lw t0, 0(%0)\n"
        "  bnez t0, 1b\n"
        "  li t0,1          # t0 = 1\n"
        "2:\n"
        "  amoswap.w.aq  t0,t0,(%0)   # t0 = oldlock & lock = 1\n"
        "  bnez          t0,2b      # Retry if previously set)\n"
        : "+r"(pmtx)
        :
        : "t0");
}

/**
 * @brief Release the mutex
 */
inline void snrt_mutex_release(volatile uint32_t *pmtx) {
    asm volatile("amoswap.w.rl  x0,x0,(%0)   # Release lock by storing 0\n"
                 : "+r"(pmtx));
}

//================================================================================
// Barrier functions
//================================================================================

/// Synchronize cores in a cluster with a hardware barrier
inline void snrt_cluster_hw_barrier() {
    uint32_t register r;

    asm volatile("lw %0, 0(%1)"
                 : "=r"(r)
                 : "r"((uint32_t)snrt_cluster_hw_barrier_addr())
                 : "memory");
}

inline void snrt_reset_barrier() { _snrt_barrier = 0; }

inline uint32_t snrt_sw_barrier_arrival() {
    return __atomic_add_fetch(&_snrt_barrier, 1, __ATOMIC_RELAXED);
}

// TODO colluca
// inline void snrt_sw_barrier_departure() {
//     _snrt_barrier = 0;
// }

// TODO colluca
// inline void snrt_sw_barrier() {
//     // Arrival phase
//     uint32_t cnt = snrt_sw_barrier_arrival();
//     // Idle phase
//     if (cnt != n) { snrt_wfi(); }
//     // Departure phase
//     else {
//         barr->barrier = 0;
//         __atomic_add_fetch(&barr->barrier_iteration, 1, __ATOMIC_RELAXED);
//     }
// }
