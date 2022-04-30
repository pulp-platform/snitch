// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/* Tests that a single core can do atomics */

#include <snrt.h>

//===============================================================
// RISC-V atomic instruction wrappers
//===============================================================

static inline uint32_t lr_w(volatile uint32_t* addr) {
    uint32_t data = 0;
    asm volatile("lr.w %[data], (%[addr])"
                 : [ data ] "+r"(data)
                 : [ addr ] "r"(addr)
                 : "memory");
    return data;
}

static inline uint32_t sc_w(volatile uint32_t* addr, uint32_t data) {
    uint32_t err = 0;
    asm volatile("sc.w %[err], %[data], (%[addr])"
                 : [ err ] "+r"(err)
                 : [ addr ] "r"(addr), [ data ] "r"(data)
                 : "memory");
    return err;
}

static inline uint32_t atomic_maxu_fetch(volatile uint32_t* addr,
                                         uint32_t data) {
    uint32_t prev = 0;
    asm volatile("amomaxu.w %[prev], %[data], (%[addr])"
                 : [ prev ] "+r"(prev)
                 : [ addr ] "r"(addr), [ data ] "r"(data)
                 : "memory");
    return prev;
}

static inline uint32_t atomic_minu_fetch(volatile uint32_t* addr,
                                         uint32_t data) {
    uint32_t prev = 0;
    asm volatile("amominu.w %[prev], %[data], (%[addr])"
                 : [ prev ] "+r"(prev)
                 : [ addr ] "r"(addr), [ data ] "r"(data)
                 : "memory");
    return prev;
}

//===============================================================
// Test all atomics on a given memory location (single core)
//===============================================================

uint32_t test_atomics(volatile uint32_t* atomic_var) {
    uint32_t tmp = 0;
    uint32_t nerrors = 0;
    uint32_t dummy_val = 42;
    uint32_t amo_operand;
    uint32_t expected_val;

    /******************************************************
     * Initialize
     ******************************************************/
    *atomic_var = 0;

    /******************************************************
     * Test 0: SC without previously acquiring lock
     *
     * We expect the SC to return an error and the lock
     * to not be overwritten.
     ******************************************************/
    amo_operand = dummy_val;
    expected_val = *atomic_var;
    tmp = sc_w(atomic_var, amo_operand);
    if (!tmp) nerrors++;
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 1: LR/SC sequence
     *
     * We expect the LR to return zero. That is the
     * initial value of lock. We expect the SC not to fail
     * and lock to be updated to the stored value.
     ******************************************************/
    expected_val = *atomic_var;
    tmp = lr_w(atomic_var);
    if (tmp != expected_val) nerrors++;

    amo_operand = dummy_val;
    expected_val = amo_operand;
    tmp = sc_w(atomic_var, amo_operand);
    if (tmp) nerrors++;
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 2: AMOADD
     ******************************************************/
    amo_operand = 1;
    expected_val += amo_operand;
    __atomic_add_fetch(atomic_var, amo_operand, __ATOMIC_RELAXED);
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 3: AMOSUB
     ******************************************************/
    amo_operand = 1;
    expected_val -= amo_operand;
    __atomic_sub_fetch(atomic_var, amo_operand, __ATOMIC_RELAXED);
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 4: AMOAND
     *
     * Clear the second least-significant bit.
     ******************************************************/
    amo_operand = ~(1 << 1);
    expected_val &= amo_operand;
    __atomic_and_fetch(atomic_var, amo_operand, __ATOMIC_RELAXED);
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 5: AMOOR
     *
     * Assert the second least-significant bit.
     ******************************************************/
    amo_operand = 1 << 1;
    expected_val |= amo_operand;
    __atomic_or_fetch(atomic_var, amo_operand, __ATOMIC_RELAXED);
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 6: AMOXOR
     *
     * Toggle the second least-significant bit.
     ******************************************************/
    amo_operand = 1 << 1;
    expected_val ^= amo_operand;
    __atomic_xor_fetch(atomic_var, amo_operand, __ATOMIC_RELAXED);
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 7: AMOMAXU
     *
     * Max between lock and the incremented value.
     * Expects incremented value to be stored.
     ******************************************************/
    amo_operand = expected_val + 1;
    expected_val = expected_val > amo_operand ? expected_val : amo_operand;
    atomic_maxu_fetch(atomic_var, amo_operand);
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 8: AMOMINU
     *
     * Max between lock and the decremented value.
     * Expects decremented value to be stored.
     ******************************************************/
    amo_operand = expected_val - 1;
    expected_val = expected_val < amo_operand ? expected_val : amo_operand;
    atomic_minu_fetch(atomic_var, amo_operand);
    if (*atomic_var != expected_val) nerrors++;

    /******************************************************
     * Test 9: AMOSWAP
     ******************************************************/
    amo_operand = dummy_val;
    expected_val = dummy_val;
    __atomic_exchange_n(atomic_var, amo_operand, __ATOMIC_RELAXED);
    if (*atomic_var != expected_val) nerrors++;

    return nerrors;
}

// Use at least two locations to test unaligned accesses
#define NUM_SPM_LOCATIONS 2
#define NUM_TCDM_LOCATIONS 2

int main() {
    uint32_t core_id = snrt_cluster_core_idx();
    uint32_t core_num = snrt_cluster_core_num();
    uint32_t nerrors = 0;

    if (core_id == 0) {
        volatile uint32_t* l1_a =
            snrt_l1alloc(NUM_TCDM_LOCATIONS * sizeof(uint32_t));
        volatile uint32_t* l3_a =
            snrt_l3alloc(NUM_SPM_LOCATIONS * sizeof(uint32_t));

        // In TCDM
        uint32_t tcdm_atomics[NUM_TCDM_LOCATIONS];
        for (int i = 0; i < NUM_TCDM_LOCATIONS; ++i) {
            nerrors += test_atomics(&l1_a[i]);
        }

        // In SPM
        for (int i = 0; i < NUM_SPM_LOCATIONS; ++i) {
            nerrors += test_atomics(&l3_a[i]);
        }
    } else {
        return 0;
    }

    return nerrors;
}
