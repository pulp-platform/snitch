// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "riscv_decls.h"

/**
 * @brief Put the hart into wait for interrupt state
 *
 */
static inline void snrt_wfi() { asm volatile("wfi"); }

static inline uint32_t mcycle() {
    uint32_t register r;
    asm volatile("csrr %0, mcycle" : "=r"(r) : : "memory");
    return r;
}

/**
 * @brief Enable interrupt source irq
 * @details Enable interrupt, either wakes from wfi or if global interrupts are
 * enabled, jumps to the IRQ handler
 *
 * @param irq one of IRQ_[S/H/M]_[SOFT/TIMER/EXT]
 * interrupts
 */
inline void snrt_interrupt_enable(uint32_t irq) { set_csr(mie, 1 << irq); }

/**
 * @brief Disable interrupt source
 * @details See snrt_interrupt_enable
 *
 * @param irq one of IRQ_[S/H/M]_[SOFT/TIMER/EXT]
 */
inline void snrt_interrupt_disable(uint32_t irq) { clear_csr(mie, 1 << irq); }

/**
 * @brief Globally enable M-mode interrupts
 * @details On an interrupt event the core will jump to
 * __snrt_crt0_interrupt_handler service the interrupt and continue normal
 * execution. Enable interrupt sources with snrt_interrupt_enable
 */
inline void snrt_interrupt_global_enable(void) {
    set_csr(mstatus, MSTATUS_MIE);  // set M global interrupt enable
}
/**
 * @brief Globally disable interrupts
 * @details
 */
inline void snrt_interrupt_global_disable(void) {
    clear_csr(mstatus, MSTATUS_MIE);
}
