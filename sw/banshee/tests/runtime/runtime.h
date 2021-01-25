// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once
#include <stddef.h>
#include <stdint.h>

#include "encoding.h"

#define PULP_NOINLINE __attribute__((noinline))

extern uint64_t l1_alloc_base;
extern uint32_t atomic_barrier;
extern uint32_t wake_up_reg;

typedef uint32_t pulp_id_t;
typedef uint32_t pulp_timer_t;

/// Obtain the number of cores in the current cluster.
static inline pulp_id_t pulp_get_core_count() {
    extern uint32_t nr_cores_address_reg;
    return nr_cores_address_reg;
}

/// Obtain the ID of the current core.
static inline pulp_id_t pulp_get_core_id() {
    pulp_id_t r;
    asm volatile("csrr %0, mhartid" : "=r"(r));
    return r;
}

/// Obtain a monotonically increasing cycle count.
static inline pulp_timer_t pulp_get_timer() { return read_csr(mcycle); }

/// A cluster-local barrier.
static inline void pulp_barrier() {
    // // The following is a software-only barrier using AMOs.
    // uint32_t core_id = pulp_get_core_id();
    // uint32_t core_count = pulp_get_core_count();
    // uint32_t mask = 1 << core_id;
    // uint32_t others = ((1 << core_count) - 1) ^ mask;
    // if (core_id == 0) {
    //     while ((__atomic_load_n(&atomic_barrier, __ATOMIC_RELAXED) & others)
    //     != others);
    //     __atomic_or_fetch(&atomic_barrier, mask, __ATOMIC_RELAXED);
    //     while ((__atomic_load_n(&atomic_barrier, __ATOMIC_RELAXED) & others)
    //     != 0);
    //     __atomic_and_fetch(&atomic_barrier, ~mask, __ATOMIC_RELAXED);
    // } else {
    //     while ((__atomic_load_n(&atomic_barrier, __ATOMIC_RELAXED) & 1) !=
    //     0);
    //     __atomic_or_fetch(&atomic_barrier, mask, __ATOMIC_RELAXED);
    //     while ((__atomic_load_n(&atomic_barrier, __ATOMIC_RELAXED) & 1) !=
    //     1);
    //     __atomic_and_fetch(&atomic_barrier, ~mask, __ATOMIC_RELAXED);
    // }

    // The following uses the hardware barrier.
    extern uint32_t barrier_reg;
    uint32_t tmp;
    asm volatile(
        "lw %[tmp], 0(%[addr]) \n"
        "mv zero, %[tmp] \n"
        : [ tmp ] "=r"(tmp)
        : [ addr ] "r"(&barrier_reg));
}

/// The different SSR data movers.
enum ssr_dm { SSR_DM0 = 0, SSR_DM1 = 1 };

/// The different dimensions.
enum ssr_dim {
    SSR_1D = 0,
    SSR_2D = 1,
    SSR_3D = 2,
    SSR_4D = 3,
};

/// The SSR configuration registers.
typedef union {
    uint32_t value __attribute__((aligned(8)));
} ssr_reg32_t;
typedef struct {
    ssr_reg32_t status;
    ssr_reg32_t repeat;
    ssr_reg32_t bounds[4];
    ssr_reg32_t stride[4];
    ssr_reg32_t _reserved4[14];
    ssr_reg32_t rptr[4];
    ssr_reg32_t wptr[4];
} ssr_cfg_t;
// extern volatile ssr_cfg_t ssr_config_reg[2]; // linker-provided address
static volatile ssr_cfg_t *const ssr_config_reg = (void *)0x204800;

// Configure an SSR data mover for a 1D loop nest.
static inline void pulp_ssr_loop_1d(enum ssr_dm dm, uint16_t b0, uint16_t i0) {
    --b0;
    ssr_config_reg[dm].bounds[0].value = b0;
    uint16_t a = 0;
    ssr_config_reg[dm].stride[0].value = i0 - a;
    a += i0 * b0;
}

// Configure an SSR data mover for a 2D loop nest.
static inline void pulp_ssr_loop_2d(enum ssr_dm dm, uint16_t b0, uint16_t b1,
                                    uint16_t i0, uint16_t i1) {
    --b0;
    --b1;
    ssr_config_reg[dm].bounds[0].value = b0;
    ssr_config_reg[dm].bounds[1].value = b1;
    uint16_t a = 0;
    ssr_config_reg[dm].stride[0].value = i0 - a;
    a += i0 * b0;
    ssr_config_reg[dm].stride[1].value = i1 - a;
    a += i1 * b1;
}

// Configure an SSR data mover for a 3D loop nest.
static inline void pulp_ssr_loop_3d(enum ssr_dm dm, uint16_t b0, uint16_t b1,
                                    uint16_t b2, uint16_t i0, uint16_t i1,
                                    uint16_t i2) {
    --b0;
    --b1;
    --b2;
    ssr_config_reg[dm].bounds[0].value = b0;
    ssr_config_reg[dm].bounds[1].value = b1;
    ssr_config_reg[dm].bounds[2].value = b2;
    uint16_t a = 0;
    ssr_config_reg[dm].stride[0].value = i0 - a;
    a += i0 * b0;
    ssr_config_reg[dm].stride[1].value = i1 - a;
    a += i1 * b1;
    ssr_config_reg[dm].stride[2].value = i2 - a;
    a += i2 * b2;
}

// Configure an SSR data mover for a 4D loop nest.
static inline void pulp_ssr_loop_4d(enum ssr_dm dm, uint16_t b0, uint16_t b1,
                                    uint16_t b2, uint16_t b3, uint16_t i0,
                                    uint16_t i1, uint16_t i2, uint16_t i3) {
    --b0;
    --b1;
    --b2;
    --b3;
    ssr_config_reg[dm].bounds[0].value = b0;
    ssr_config_reg[dm].bounds[1].value = b1;
    ssr_config_reg[dm].bounds[2].value = b2;
    ssr_config_reg[dm].bounds[3].value = b3;
    uint16_t a = 0;
    ssr_config_reg[dm].stride[0].value = i0 - a;
    a += i0 * b0;
    ssr_config_reg[dm].stride[1].value = i1 - a;
    a += i1 * b1;
    ssr_config_reg[dm].stride[2].value = i2 - a;
    a += i2 * b2;
    ssr_config_reg[dm].stride[3].value = i3 - a;
    a += i3 * b3;
}

/// Enable SSR.
static inline void pulp_ssr_enable() { asm volatile("csrsi 0x7C0, 1"); }

/// Disable SSR.
static inline void pulp_ssr_disable() { asm volatile("csrci 0x7C0, 1"); }

/// Start a streaming read.
static inline void pulp_ssr_read(enum ssr_dm dm, enum ssr_dim dim, void *ptr) {
    ssr_config_reg[dm].rptr[dim].value = (uint32_t)ptr;
}

/// Start a streaming write.
static inline void pulp_ssr_write(enum ssr_dm dm, enum ssr_dim dim, void *ptr) {
    ssr_config_reg[dm].wptr[dim].value = (uint32_t)ptr;
}

/// Synchronize the integer and float pipelines.
static inline void fpu_fence() { asm volatile("fmv.x.w zero, fa0"); }
