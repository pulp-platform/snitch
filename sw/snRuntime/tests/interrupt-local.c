// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "encoding.h"
#include "printf.h"
#include "snrt.h"

// Test output printf
// #define tprintf(...) printf(__VA_ARGS__)
#define tprintf(...) while (0)

// Progress printf
// #define pprintf(...) printf(__VA_ARGS__)
#define pprintf(...) while (0)

volatile static int32_t *cluster_flags[8];

void sleep_loop(uint32_t cluster_core_idx, volatile int32_t *flag) {
    snrt_interrupt_enable(IRQ_M_CLUSTER);
    for (unsigned i = 8; i; --i) {
        snrt_wfi();
        snrt_int_cluster_clr(1 << cluster_core_idx);
        __atomic_add_fetch(flag, 1, __ATOMIC_RELAXED);
        while (__atomic_load_n(flag, __ATOMIC_RELAXED))
            ;
        snrt_cluster_hw_barrier();
    }
    snrt_interrupt_disable(IRQ_M_CLUSTER);
}

int main() {
    unsigned cluster_idx = snrt_cluster_idx();
    unsigned core_idx = snrt_global_core_idx();
    unsigned core_num = snrt_global_core_num();
    unsigned cluster_core_idx = snrt_cluster_core_idx();
    unsigned cluster_core_num = snrt_cluster_core_num();
    volatile unsigned tmp;

    // cluster master cores init cluster_flags
    if (cluster_core_idx == 0) {
        cluster_flags[cluster_idx] = (int32_t *)snrt_l1alloc(sizeof(int32_t));
        *cluster_flags[cluster_idx] = 0;
    }
    snrt_cluster_hw_barrier();

    // Test 1: Use the cluster-local interrupt for fast synchronization inside
    // cluster
    if (cluster_core_idx != 0) {
        sleep_loop(cluster_core_idx, cluster_flags[cluster_idx]);
    } else {
        for (unsigned i = 8; i; --i) {
            tprintf("wake %d..", i);
            snrt_int_cluster_set(~0x1 & ((1 << cluster_core_num) - 1));
            while (
                __atomic_load_n(cluster_flags[cluster_idx], __ATOMIC_RELAXED) !=
                (int32_t)(cluster_core_num - 1))
                ;
            *cluster_flags[cluster_idx] = 0;
            snrt_cluster_hw_barrier();
            tprintf("OK!\n");
        }
    }
    snrt_cluster_hw_barrier();
    if (core_idx == 0) pprintf("Test 1 complete\n");

    // // Test 2: Core 0 sends interrupts to each hart sequentially and
    // // polls the flag and checks for correctness
    // if (cluster_core_idx == 0) {
    //     for (unsigned i = 1; i < cluster_core_num; i++) {
    //         tprintf("IRQ %d ..", i);
    //         *cluster_flags[cluster_idx] = -1;
    //         snrt_int_cluster_set(1 << i);
    //         while (*cluster_flags[cluster_idx] != (int)i)
    //             ;
    //         tprintf("OK\n", *cluster_flags[cluster_idx]);
    //     }
    // } else {
    //     snrt_interrupt_enable(IRQ_M_CLUSTER);
    //     snrt_interrupt_global_enable();
    //     snrt_wfi();
    //     read_csr(mie);
    //     read_csr(mip);
    //     snrt_interrupt_cause();
    //     snrt_interrupt_global_disable();
    // }
    // snrt_cluster_hw_barrier();
    // if (core_idx == 0) pprintf("Test 2 complete\n");

    // Test 3: Make sure we can set a cluster-local interrupt that is latched if
    // a hart is not in wfi and the wfi becomes a NOP
    if (cluster_core_idx == 0) {
        // set the interrupt and wait for cluster cores to enable interrupts
        snrt_int_cluster_set(~0x1 & ((1 << cluster_core_num) - 1));
        snrt_cluster_hw_barrier();
    } else {
        snrt_cluster_hw_barrier();
        // wait a bit so that the cl-clint has the new values, then enable
        // interrupts and do a wfi
        tmp = 20;
        while (--tmp)
            ;
        snrt_interrupt_enable(IRQ_M_CLUSTER);
        snrt_wfi();  // This WFI should be a NOP
        if (snrt_interrupt_cause() & IRQ_M_CLUSTER) {
            snrt_int_cluster_clr(1 << cluster_core_idx);
        }
        snrt_interrupt_disable(IRQ_M_CLUSTER);
    }
    snrt_cluster_hw_barrier();
    if (core_idx == 0) pprintf("Test 3 complete\n");

    return 0;
}

void irq_m_cluster(uint32_t cluster_core_idx) {
    snrt_int_cluster_clr(1 << cluster_core_idx);
    __atomic_add_fetch(cluster_flags[snrt_cluster_idx()], 1 + cluster_core_idx,
                       __ATOMIC_RELAXED);
}
