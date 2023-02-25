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

volatile static int32_t global_flag;

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

    // Test1: Core 0 sends interrupts to each hart sequentially and
    // polls the flag and checks for correctness
    if (core_idx == 0) {
        for (unsigned i = 1; i < core_num; i++) {
            tprintf("IRQ %d ..", i);
            global_flag = -1;
            snrt_int_sw_set(snrt_global_core_base_hartid() + i);
            while (global_flag != (int)i)
                ;
            tprintf("OK\n", global_flag);
        }
    } else {
        snrt_interrupt_enable(IRQ_M_SOFT);
        snrt_interrupt_global_enable();
        asm volatile("wfi");
        snrt_interrupt_global_disable();
    }
    snrt_global_barrier();
    if (core_idx == 0) pprintf("Test 1 complete\n");

    // Test2: Enable software interrupt wihout jumping to the exception
    // address
    if (core_idx == 0) {
        for (unsigned i = 1; i < core_num; i++) {
            tprintf("trig %d..", i);
            global_flag = -1;
            snrt_int_sw_set(snrt_global_core_base_hartid() + i);
            while (global_flag != ((int)i << 8))
                ;
            tprintf("OK\n", global_flag);
        }
    } else {
        snrt_interrupt_enable(IRQ_M_SOFT);
        asm volatile("wfi");
        // interrupts are disabled so the mcause register is not updated
        if (snrt_int_sw_get(snrt_hartid())) {
            snrt_int_sw_clear(snrt_global_core_base_hartid() + core_idx);
            global_flag = core_idx << 8;
        }
    }
    snrt_global_barrier();
    if (core_idx == 0) pprintf("Test 2 complete\n");

    return 0;
}

void irq_m_soft(uint32_t core_idx) {
    snrt_int_sw_clear(snrt_global_core_base_hartid() + core_idx);
    global_flag = core_idx;
}
