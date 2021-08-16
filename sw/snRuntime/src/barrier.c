// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"
#include "team.h"

extern void _snrt_cluster_barrier();

/// Synchronize cores in a cluster with a hardware barrier
void snrt_cluster_hw_barrier() { _snrt_cluster_barrier(); }

/// Synchronize cores in a cluster with a software barrier
void snrt_cluster_sw_barrier() {
    // Remember previous iteration
    struct snrt_barrier *barrier_ptr =
        &_snrt_team_current->root->cluster_barrier;
    uint32_t prev_barrier_iteration = barrier_ptr->barrier_iteration;
    uint32_t barrier =
        __atomic_add_fetch(&barrier_ptr->barrier, 1, __ATOMIC_RELAXED);

    // Increment the barrier counter
    if (barrier == snrt_cluster_core_num()) {
        barrier_ptr->barrier = 0;
        __atomic_add_fetch(&barrier_ptr->barrier_iteration, 1,
                           __ATOMIC_RELAXED);
    } else {
        // Some threads have not reached the barrier --> Let's wait
        while (prev_barrier_iteration == barrier_ptr->barrier_iteration)
            ;
    }
}

static volatile struct snrt_barrier global_barrier
    __attribute__((section(".dram")));

/// Synchronize clusters globally with a global software barrier
void snrt_global_barrier() {
    // Remember previous iteration
    struct snrt_barrier *barrier_ptr = &global_barrier;
    uint32_t prev_barrier_iteration = barrier_ptr->barrier_iteration;
    uint32_t barrier =
        __atomic_add_fetch(&barrier_ptr->barrier, 1, __ATOMIC_RELAXED);

    // Increment the barrier counter
    if (barrier == snrt_global_core_num()) {
        barrier_ptr->barrier = 0;
        __atomic_add_fetch(&barrier_ptr->barrier_iteration, 1,
                           __ATOMIC_RELAXED);
    } else {
        // Some threads have not reached the barrier --> Let's wait
        while (prev_barrier_iteration == barrier_ptr->barrier_iteration)
            ;
    }
}
