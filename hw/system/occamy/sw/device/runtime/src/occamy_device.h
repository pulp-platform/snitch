// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "heterogeneous_runtime.h"

typedef enum { SYNC_ALL, SYNC_CLUSTERS, SYNC_NONE } sync_t;

inline uint32_t __attribute__((const)) snrt_quadrant_idx() {
    return snrt_cluster_idx() / N_CLUSTERS_PER_QUAD;
}

inline void post_wakeup_cl() { snrt_int_clr_mcip(); }

inline comm_buffer_t* __attribute__((const)) get_communication_buffer() {
    return (comm_buffer_t*)(*soc_ctrl_scratch_ptr(2));
}

inline uint32_t elect_director(uint32_t num_participants) {
    uint32_t loser;
    uint32_t prev_val;
    uint32_t winner;

    prev_val = __atomic_fetch_add(snrt_mutex(), 1, __ATOMIC_RELAXED);
    winner = prev_val == (num_participants - 1);

    // last core must reset counter
    if (winner) *snrt_mutex() = 0;

    return winner;
}

// This function returns control from the Snitches to CVA6.
// For this, only one (DM) core has to send an interrupt to CVA6.
// Cores may have to be synchronized before this can happen.
// The `sync` argument is used to specify which cores still need
// to be synchronized.
inline void return_to_cva6(sync_t sync) {
    // Optionally synchronize cores in each cluster
    if (sync == SYNC_ALL) snrt_cluster_hw_barrier();
    // Optionally synchronize clusters
    if (sync != SYNC_NONE) {
        if (snrt_is_dm_core()) {
            uint32_t cnt =
                __atomic_add_fetch(&(_snrt_barrier.cnt), 1, __ATOMIC_RELAXED);
            if (cnt == snrt_cluster_num()) {
                _snrt_barrier.cnt = 0;
                snrt_int_sw_set(0);
            }
        }
    }
    // Otherwise assume cores are already synchronized and only
    // one core calls this function
    else {
        snrt_int_sw_set(0);
    }
}
