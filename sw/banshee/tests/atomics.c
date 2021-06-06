// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

volatile uint32_t l2 = 0;

static inline int check_result(volatile uint32_t* const addr, uint32_t exp) {
    pulp_barrier();
    int res = (*addr != exp);
    pulp_barrier();
    return res;
}

static int check_amos(volatile uint32_t* const addr) {
    uint32_t core_id = pulp_get_core_id();
    uint32_t tmp = 0;
    pulp_barrier();
    // Check atomic swap
    tmp = __atomic_exchange_n(addr, core_id + 1, __ATOMIC_RELAXED);
    if (core_id + 1 == tmp) return 1;  // Atomic swap failed
    pulp_barrier();
    // Atomic add --> n(n+1)/2 = 36
    __atomic_fetch_add(addr, tmp, __ATOMIC_RELAXED);
    if (check_result(addr, 36)) return 1;

    // Atomic max
    asm volatile("amomax.w  %0, %1, (%2)"
                 : "=r"(tmp)
                 : "r"(core_id - 4), "r"(addr)
                 : "memory");
    if (check_result(addr, 36)) return 1;

    // Atomic maxu
    asm volatile("amomaxu.w  %0, %1, (%2)"
                 : "=r"(tmp)
                 : "r"(core_id + 36), "r"(addr)
                 : "memory");
    if (check_result(addr, 36 + 7)) return 1;

    // Atomic min
    asm volatile("amomin.w  %0, %1, (%2)"
                 : "=r"(tmp)
                 : "r"(core_id - 5), "r"(addr)
                 : "memory");
    if (check_result(addr, -5)) return 1;

    // Atomic minu
    asm volatile("amominu.w  %0, %1, (%2)"
                 : "=r"(tmp)
                 : "r"(core_id), "r"(addr)
                 : "memory");
    if (check_result(addr, 0)) return 1;

    // Atomic or
    __atomic_fetch_or(addr, (0x1 << (core_id % 8)), __ATOMIC_RELAXED);
    if (check_result(addr, 0xFF)) return 1;

    // Atomic and
    __atomic_fetch_and(addr, (0x1 << (core_id % 8)), __ATOMIC_RELAXED);
    if (check_result(addr, 0)) return 1;

    // Atomic xor
    __atomic_fetch_xor(addr, (0x1 << (core_id % 6)), __ATOMIC_RELAXED);
    if (check_result(addr, 0x3C)) return 1;

    uint32_t const n_iter = 100;
    for (int i = 0; i < n_iter; ++i) {
        uint32_t counter;
        uint32_t result;
        do {
            asm volatile("lr.w %0, (%1)" : "=r"(counter) : "r"(addr));
            counter++;
            asm volatile("sc.w %0, %1, (%2)"
                         : "=r"(result)
                         : "r"(counter), "r"(addr));
        } while (result);
    }
    if (check_result(addr, 0x3C + 8 * n_iter)) return 1;

    return 0;
}

int main(uint32_t core_id, uint32_t core_num) {
    volatile uint32_t* l1 = (void*)&l1_alloc_base;
    // Test hardcoded for 8 cores
    if (core_num != 8) return -1;
    // Init
    *l1 = 0;
    l2 = 0;
    pulp_barrier();
    if (check_amos(l1)) return 1;
    if (check_amos(&l2)) return 1;
    return 0;
}
