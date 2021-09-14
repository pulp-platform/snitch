// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "encoding.h"
#include "printf.h"
#include "snrt.h"

int reboot = 0;

// #define tprintf(f_, ...) printf((f_), __VA_ARGS__)
#define tprintf(f_, ...) while (0)

volatile static int32_t INTERRUPT_FLAG;
volatile static uint32_t *p_scratch;
volatile static uint32_t *p_exit;

void sleep_loop(uint32_t cluster_core_idx) {
    uint32_t do_exit = 0;
    snrt_interrupt_enable(IRQ_M_CLUSTER);
    while (!do_exit) {
        snrt_wfi();
        snrt_int_cluster_clr(1 << cluster_core_idx);
        if (__atomic_load_n(p_exit, __ATOMIC_RELAXED)) do_exit = 1;
        ;
        __atomic_add_fetch(p_scratch, 1, __ATOMIC_RELAXED);
    }
    snrt_interrupt_disable(IRQ_M_CLUSTER);
}

int main() {
    unsigned core_idx = snrt_global_core_idx();
    unsigned core_num = snrt_global_core_num();
    unsigned cluster_core_idx = snrt_cluster_core_idx();
    unsigned cluster_core_num = snrt_cluster_core_num();

    // Test1: Core 0 sends interrupts to each hart sequentially and
    // polls the flag and checks for correctness
    if (core_idx == 0) {
        for (unsigned i = 1; i < core_num; i++) {
            tprintf("IRQ %d ..", i);
            INTERRUPT_FLAG = -1;
            snrt_int_sw_set(snrt_global_core_base_hartid() + i);
            while (INTERRUPT_FLAG != (int)i)
                ;
            tprintf("OK\n", INTERRUPT_FLAG);
        }
    } else {
        snrt_interrupt_enable(IRQ_M_SOFT);
        snrt_interrupt_global_enable();
        asm volatile("wfi");
        snrt_interrupt_global_disable();
    }

    snrt_cluster_hw_barrier();

    // Test2: Enable software interrupt wihout jumping to the exception
    // address
    if (core_idx == 0) {
        for (unsigned i = 1; i < core_num; i++) {
            tprintf("trig %d .. ", i);
            INTERRUPT_FLAG = -1;
            snrt_int_sw_set(snrt_global_core_base_hartid() + i);
            while (INTERRUPT_FLAG != ((int)i << 8))
                ;
            tprintf("OK\n", INTERRUPT_FLAG);
        }
    } else {
        snrt_interrupt_enable(IRQ_M_SOFT);
        asm volatile("wfi");
        if (snrt_interrupt_cause() & IRQ_M_SOFT) {
            snrt_int_sw_clear(snrt_global_core_base_hartid() + core_idx);
            INTERRUPT_FLAG = core_idx << 8;
        }
    }

    // Test3: Use the cluster-local interrupt for fast synchronization inside
    // cluster
    if (cluster_core_idx == 0) {
        p_scratch = (uint32_t *)snrt_l1alloc(sizeof(uint32_t));
        *p_scratch = 0;
        p_exit = (uint32_t *)snrt_l1alloc(sizeof(uint32_t));
        *p_exit = 0;
    }
    snrt_cluster_hw_barrier();

    if (cluster_core_idx != 0) {
        sleep_loop(cluster_core_idx);
    } else {
        for (unsigned i = 8; i; --i) {
            tprintf("wake %d\n", i);
            *p_exit = i == 1 ? 1 : 0;
            snrt_int_cluster_set(~0x1 & ((1 << cluster_core_num) - 1));
            while (__atomic_load_n(p_scratch, __ATOMIC_RELAXED) !=
                   (cluster_core_num - 1))
                ;
            *p_scratch = 0;
            tprintf("ok!\n");
        }
    }
    snrt_global_barrier();

    // Test4: Core 0 sends interrupts to each hart sequentially and
    // polls the flag and checks for correctness
    if (cluster_core_idx == 0) {
        for (unsigned i = 1; i < cluster_core_num; i++) {
            tprintf("IRQ %d ..", i);
            INTERRUPT_FLAG = -1;
            snrt_int_cluster_set(1 << i);
            while (INTERRUPT_FLAG != (int)i)
                ;
            tprintf("OK\n", INTERRUPT_FLAG);
        }
    } else {
        snrt_interrupt_enable(IRQ_M_CLUSTER);
        snrt_interrupt_global_enable();
        snrt_wfi();
        snrt_interrupt_global_disable();
    }
    snrt_global_barrier();

    return 0;
}

void irq_m_soft(uint32_t core_idx) {
    snrt_int_sw_clear(snrt_global_core_base_hartid() + core_idx);
    INTERRUPT_FLAG = core_idx;
}

void irq_m_cluster(uint32_t cluster_core_idx) {
    snrt_int_cluster_clr(1 << cluster_core_idx);
    INTERRUPT_FLAG = cluster_core_idx;
}
