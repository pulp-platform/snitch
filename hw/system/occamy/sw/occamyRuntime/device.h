// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"
#include "occamy.h"
#include "occamyRuntime.h"
#include "occamy_soc_ctrl.h"

extern volatile __thread uint32_t *clint_p;

static volatile uint32_t race_mutex = 0;
extern volatile uint32_t *clint_mutex;

static inline volatile uint32_t* soc_ctrl_scratch_ptr(uint32_t idx) {
    volatile uint32_t* const soc_ctrl_scratch_base =
        (volatile uint32_t*)(SOC_CTRL_BASE_ADDR +
                             OCCAMY_SOC_SCRATCH_0_REG_OFFSET);
    return soc_ctrl_scratch_base +
           (idx / OCCAMY_SOC_SCRATCH_SCRATCH_FIELDS_PER_REG);
}

static inline uint32_t elect_director(uint32_t num_participants) {
    uint32_t loser;
    uint32_t prev_val;
    uint32_t winner;

    prev_val = __atomic_fetch_add(&race_mutex, 1, __ATOMIC_RELAXED);
    winner = prev_val == (num_participants - 1);

    // last core must reset counter
    if (winner) race_mutex = 0;

    return winner;
}

static inline void post_wakeup() {

    uint32_t hartid = snrt_hartid();
    volatile uint32_t *mutex = &(clint_mutex[hartid/32]);
    volatile uint32_t *msip_p = clint_p + ((hartid & ~0x1f) >> 5);

    asm volatile(
        // Acquire lock
        "1:                          \n"
        "  lw           t0, 0(%0)    \n"
        "  bnez         t0, 1b       \n"
        "  li           t0, 1        \n"
        "2:                          \n"
        "  amoswap.w.aq t0, t0, (%0) \n"
        "  bnez         t0, 2b       \n"
        // Clear interrupt
        "  lw           t1, 0(%1)    \n"
        "  li           t2, 1        \n"
        "  sll          t2, t2, %2   \n"
        "  not          t2, t2       \n"
        "  and          t1, t1, t2   \n"
        "  sw           t1, 0(%1)    \n"
        // Release lock
        "  amoswap.w.rl x0, x0, (%0) \n"
        : "+r"(mutex)
        : "r"(msip_p), "r"(hartid)
        : "t0", "t1", "memory"
    );
}

static inline void post_wakeup_cl() {
    uint32_t hartid = snrt_cluster_core_idx();
    snrt_int_cluster_clr(1 << hartid);
}

static inline uint32_t is_master() {
    return snrt_cluster_core_idx() == 0;
}

// Post wake-up actions e.g. clear interrupts
static inline void post_hierarchical_wakeup() {
    uint32_t hartid = snrt_hartid();
    volatile uint32_t* mutex = &clint_mutex[hartid/32];
    if (is_master()) {
        snrt_mutex_ttas_lock(mutex);
        *(clint_p + ((hartid & ~0x1f) >> 5)) &= ~(1 << (hartid & 0x1f));
        // wait_sw_interrupt_cleared(); // TODO: for 100% correctness this should stay
        snrt_mutex_release(mutex);
    }
    else {
        snrt_int_cluster_clr(1 << snrt_cluster_core_idx());
        // wait_cl_interrupt_cleared(); // TODO: for 100% correctness this should stay
    }
}

static inline volatile uint32_t __rt_get_timer() {
    uint32_t register r;
    asm volatile ("csrr %0, mcycle" : "=r"(r));
    return r;
}

static inline void return_hierarchical() {
    volatile uint32_t* clint = snrt_peripherals()->clint;
    // Synchronize all cores
    // Hardware barriers synchronize cores intra-cluster,
    // then every DMA core participates in a race where
    // the last one arriving wins the race.
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core() && elect_director(N_CLUSTERS)) {
        __rt_get_timer();
        *(clint + ((0 & ~0x1f) >> 5)) |= (1 << (0 & 0x1f));
    } else {
        __rt_get_timer();
    }
}

static inline comm_buffer_t* get_communication_buffer() {
    return (comm_buffer_t *)(*soc_ctrl_scratch_ptr(2));
}
