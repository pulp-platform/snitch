// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "encoding.h"
#include "snrt.h"

//================================================================================
// ISR definitions
//================================================================================

void irq_m_soft(uint32_t hartid);
void irq_m_timer(uint32_t hartid);
void irq_m_ext(uint32_t hartid);

//================================================================================
// Public functions
//================================================================================

/**
 * @brief Interrupt service routine called by start.S on interrupts and
 * exceptions
 * @details
 *
 * @param hartid hart ID of the interrupted core
 */
void __snrt_isr(uint32_t hartid) {
    uint32_t cause = read_csr(mcause);
    // dispatch interrupt
    if (cause & MCAUSE_INTERRUPT) {
        switch (cause & ~MCAUSE_INTERRUPT) {
            case IRQ_M_SOFT:
                irq_m_soft(hartid);
                break;
            case IRQ_M_TIMER:
                irq_m_timer(hartid);
                break;
            case IRQ_M_EXT:
                irq_m_ext(hartid);
                break;
        }
    } else {
        // exceptions not handled, halt
        while (1)
            ;
    }
}

/**
 * @brief Clear SW interrupt in CLINT
 * @details
 *
 * @param hartid Target interrupt to clear
 */
void snrt_int_sw_clear(uint32_t hartid) {
    *(snrt_peripherals()->clint + ((hartid & ~0x1f) >> 5)) &=
        ~(1 << (hartid & 0x1f));
}

/**
 * @brief Set SW interrupt in CLINT
 * @details
 *
 * @param hartid Target interrupt to set
 */
void snrt_int_sw_set(uint32_t hartid) {
    *(snrt_peripherals()->clint + ((hartid & ~0x1f) >> 5)) |=
        (1 << (hartid & 0x1f));
}

//================================================================================
// Weak definition of IRQ handler
//================================================================================

void __attribute__((weak)) irq_m_soft(uint32_t hartid) {
    snrt_int_sw_clear(hartid);
}

void __attribute__((weak)) irq_m_timer(uint32_t hartid) {}

void __attribute__((weak)) irq_m_ext(uint32_t hartid) {}
