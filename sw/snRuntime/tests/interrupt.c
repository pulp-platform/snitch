// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "encoding.h"
#include "printf.h"
#include "snrt.h"

int reboot = 0;

#define tprintf(f_, ...) printf((f_), __VA_ARGS__)
// #define tprintf(f_, ...) while (0

volatile static int32_t INTERRUPT_FLAG;

int main() {
    unsigned core_idx = snrt_global_core_idx();
    unsigned core_num = snrt_global_core_num();

    // Test1: Core 0 sends interrupts to each hart sequentially and
    // polls the flag and checks for correctness
    if (core_idx == 0) {
        for (unsigned i = 1; i < core_num; i++) {
            tprintf("IRQ %d ..", i);
            INTERRUPT_FLAG = -1;
            snrt_int_sw_set(i);
            while (INTERRUPT_FLAG != (int)i)
                ;
            tprintf("OK\n", INTERRUPT_FLAG);
        }
    } else {
        snrt_interrupt_enable(IRQ_M_SOFT);
        snrt_interrupt_global_enable();
        asm volatile("wfi");
        asm volatile("nop");
        snrt_interrupt_global_disable();
    }

    snrt_cluster_hw_barrier();

    // Test2: Enable software interrupt wihout jumping to the exception address
    if (core_idx == 0) {
        for (unsigned i = 1; i < core_num; i++) {
            tprintf("trig %d .. ", i);
            INTERRUPT_FLAG = -1;
            snrt_int_sw_set(i);
            while (INTERRUPT_FLAG != ((int)i << 8))
                ;
            tprintf("OK\n", INTERRUPT_FLAG);
        }
    } else {
        snrt_interrupt_enable(IRQ_M_SOFT);
        asm volatile("wfi");
        if (snrt_interrupt_cause() & IRQ_M_SOFT) {
            snrt_int_sw_clear(core_idx);
            INTERRUPT_FLAG = core_idx << 8;
        }
    }
}

void irq_m_soft(uint32_t hartid) {
    snrt_int_sw_clear(hartid);
    INTERRUPT_FLAG = hartid;
}
