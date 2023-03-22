// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "dm.h"
#include "encoding.h"
#include "printf.h"
#include "snrt.h"

// #define tprintf(...) printf(__VA_ARGS__)
#define tprintf(...) while (0)

volatile static uint32_t sum = 0;

uint32_t compare(uint32_t *a, uint32_t *b, uint32_t n) {
    uint32_t mismatch = 0;
    for (uint32_t i = 0; i < n; ++i) {
        if (a[i] != b[i]) {
            ++mismatch;
        }
    }
    return mismatch;
}

int main() {
    unsigned core_idx = snrt_cluster_core_idx();
    unsigned core_num = snrt_cluster_core_num();
    unsigned err = 0, mismatch;
    static unsigned arg = 0;

    dm_init();

    if (core_idx == 0) {
        // Wait for DM to be ready
        dm_wait_ready();
    } else if (snrt_is_dm_core()) {
        // Put DM core in its event loop
        dm_main();
        return 0;
    } else {
        // all other cores exit, this is a single-hart test
        return 0;
    }

    // Prepare data buffers
    const uint32_t n_elem = 128, n_rep = 4;
    uint32_t *l1_a, *l1_b, *l1_c, *l1_d, *l1_2d_a;
    l1_a = snrt_l1alloc(n_elem * sizeof(uint32_t));
    l1_b = snrt_l1alloc(n_elem * sizeof(uint32_t));
    l1_c = snrt_l1alloc(n_elem * sizeof(uint32_t));
    l1_d = snrt_l1alloc(n_elem * sizeof(uint32_t));
    l1_2d_a = snrt_l1alloc(n_elem * n_rep * sizeof(uint32_t));
    uint32_t *l3_a, *l3_2d_a;
    l3_a = snrt_l3alloc(n_elem * sizeof(uint32_t));
    l3_2d_a = snrt_l3alloc(n_elem * n_rep * sizeof(uint32_t));

    tprintf("-- Test 1: L1 -> L1\n");
    for (uint32_t i = 0; i < n_elem; ++i) l1_a[i] = i;
    dm_memcpy_async(l1_b, l1_a, n_elem * sizeof(uint32_t));
    dm_wait();
    mismatch = compare(l1_a, l1_b, n_elem);
    if (mismatch) {
        tprintf("  failed with %d mismatches\n", mismatch);
        err |= 1 << 1;
    }

    tprintf("-- Test 2: L1 <- L1\n");
    for (uint32_t i = 0; i < n_elem; ++i) l1_b[i] = i + 1;
    dm_memcpy_async(l1_a, l1_b, n_elem * sizeof(uint32_t));
    dm_wait();
    mismatch = compare(l1_a, l1_b, n_elem);
    if (mismatch) {
        tprintf("  failed with %d mismatches\n", mismatch);
        err |= 1 << 2;
    }

    tprintf("-- Test 3: Dual L1 -> L1\n");
    for (uint32_t i = 0; i < n_elem; ++i) l1_a[i] = i + 2;
    for (uint32_t i = 0; i < n_elem; ++i) l1_c[i] = i + 3;
    dm_memcpy_async(l1_b, l1_a, n_elem * sizeof(uint32_t));
    dm_memcpy_async(l1_d, l1_c, n_elem * sizeof(uint32_t));
    dm_wait();
    mismatch = compare(l1_a, l1_b, n_elem);
    mismatch += compare(l1_c, l1_d, n_elem);
    if (mismatch) {
        tprintf("  failed with %d mismatches\n", mismatch);
        err |= 1 << 3;
    }

    tprintf("-- Test 4: 2D L1 -> L2\n");
    for (uint32_t i = 0; i < n_elem * n_rep; ++i) l1_2d_a[i] = i + 4;
    dm_memcpy2d_async((uint64_t)l1_2d_a, (uint64_t)l3_2d_a,
                      n_elem * sizeof(uint32_t), n_elem * sizeof(uint32_t),
                      n_elem * sizeof(uint32_t), n_rep, 0);
    // uint64_t src, uint64_t dst, uint32_t size, uint32_t
    // sstrd, uint32_t dstrd,
    //     uint32_t nreps, uint32_t cfg
    dm_wait();
    mismatch = compare(l1_2d_a, l3_2d_a, n_elem * n_rep);
    if (mismatch) {
        tprintf("  failed with %d mismatches\n", mismatch);
        err |= 1 << 4;
    }

    // exit
    dm_exit();
    return err;
}
