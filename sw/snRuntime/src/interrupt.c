// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "encoding.h"
#include "printf.h"
#include "snrt.h"
#include "team.h"

//================================================================================
// Macros
//================================================================================

/// The cluster-local clint is in the cluster peripheral system which has 64 bit
/// register width
#define cl_clint_set(x) *(cl_clint_p + 0) = (x)
#define cl_clint_clr(x) *(cl_clint_p + 2) = (x)

//================================================================================
// Data
//================================================================================
static volatile uint32_t clint_mutex = 0;
static __thread volatile uint32_t *clint_p;
static __thread volatile uint32_t *cl_clint_p;

//================================================================================
// ISR definitions
//================================================================================

void irq_m_soft(uint32_t core_idx);
void irq_m_timer(uint32_t core_idx);
void irq_m_ext(uint32_t core_idx);
void irq_m_cluster(uint32_t core_idx);

//================================================================================
// Public functions
//================================================================================

void snrt_int_init(struct snrt_team_root *team) {
    // Put the clint address in tls for faster access
    clint_p = team->peripherals.clint;
    cl_clint_p = team->peripherals.cl_clint;
}

/**
 * @brief Interrupt service routine called by start.S on interrupts and
 * exceptions
 * @details
 *
 * @param hartid hart ID of the interrupted core
 */
void __snrt_isr(void) {
    uint32_t core_idx = snrt_global_core_idx();
    uint32_t cause = read_csr(mcause);
    // dispatch interrupt
    if (cause & MCAUSE_INTERRUPT) {
        switch (cause & ~MCAUSE_INTERRUPT) {
            case IRQ_M_SOFT:
                irq_m_soft(core_idx);
                break;
            case IRQ_M_TIMER:
                irq_m_timer(core_idx);
                break;
            case IRQ_M_EXT:
                irq_m_ext(core_idx);
                break;
            case IRQ_M_CLUSTER:
                core_idx = snrt_cluster_core_idx();
                irq_m_cluster(core_idx);
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
    snrt_mutex_lock(&clint_mutex);
    *(clint_p + ((hartid & ~0x1f) >> 5)) &= ~(1 << (hartid & 0x1f));
    snrt_mutex_release(&clint_mutex);
}

/**
 * @brief Set SW interrupt in CLINT
 * @details
 *
 * @param hartid Target interrupt to set
 */
void snrt_int_sw_set(uint32_t hartid) {
    snrt_mutex_lock(&clint_mutex);
    *(clint_p + ((hartid & ~0x1f) >> 5)) |= (1 << (hartid & 0x1f));
    snrt_mutex_release(&clint_mutex);
}

/**
 * @brief Read SW interrupt for hartid in CLINT
 *
 * @param hartid hartid to poll for interrupt flag
 * @return uint32_t 0 if no SW interrupt is pending, 1 otherwise
 */
uint32_t snrt_int_sw_get(uint32_t hartid) {
    snrt_mutex_lock(&clint_mutex);
    uint32_t ret = *(clint_p + ((hartid & ~0x1f) >> 5)) >> (hartid & 0x1f);
    snrt_mutex_release(&clint_mutex);
    return ret;
}

/**
 * @brief Set a `mask` of bits in the CLINT register `reg_off` (word offset).
 * This can be used to send interrupts to a set of cores
 *
 * @param reg_off CLINT register offset in word (=byte_off/4)
 * @param mask bit mask to set
 */
void snrt_int_clint_set(uint32_t reg_off, uint32_t mask) {
    snrt_mutex_lock(&clint_mutex);
    *(clint_p + reg_off) |= mask;
    snrt_mutex_release(&clint_mutex);
}

/**
 * @brief Go to wfi and exit with cleared SW interrupt if a SW interrupt
 * is presen
 *
 */
void snrt_int_sw_poll(void) {
    uint32_t exit = 0, hartid = snrt_hartid();
    while (!exit) {
        snrt_wfi();
        snrt_mutex_lock(&clint_mutex);
        if (*(clint_p + ((hartid & ~0x1f) >> 5)) >> (hartid & 0x1f)) {
            *(clint_p + ((hartid & ~0x1f) >> 5)) &= ~(1 << (hartid & 0x1f));
            exit = 1;
        }
        snrt_mutex_release(&clint_mutex);
    }
}

/**
 * @brief Write mask to the cluster-local interrupt clear register
 * @param mask set bit at X clears the interrupt of hart X
 */
void snrt_int_cluster_clr(uint32_t mask) { cl_clint_clr(mask); }

/**
 * @brief Write mask to the cluster-local interrupt set register
 * @param mask set bit at X sets the interrupt of hart X
 */
void snrt_int_cluster_set(uint32_t mask) { cl_clint_set(mask); }

//================================================================================
// Weak definition of IRQ handler
//================================================================================

void __attribute__((weak)) irq_m_soft(uint32_t core_idx) {
    snrt_int_sw_clear(core_idx);
}

void __attribute__((weak)) irq_m_timer(uint32_t core_idx) { (void)core_idx; }

void __attribute__((weak)) irq_m_ext(uint32_t core_idx) { (void)core_idx; }

void __attribute__((weak)) irq_m_cluster(uint32_t cluster_core_idx) {
    snrt_int_cluster_clr(1 << cluster_core_idx);
}
