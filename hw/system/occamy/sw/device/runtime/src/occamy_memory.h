// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

extern __thread uint32_t _snrt_cluster_hw_barrier;

inline uint32_t __attribute__((const)) snrt_l1_start_addr() {
    return cluster_tcdm_start_addr(snrt_cluster_idx());
}

inline uint32_t __attribute__((const)) snrt_l1_end_addr() {
    return cluster_tcdm_end_addr(snrt_cluster_idx());
}

inline volatile uint32_t* __attribute__((const)) snrt_clint_mutex_ptr() {
    return &(get_communication_buffer()->lock);
}

inline volatile uint32_t* __attribute__((const))
snrt_clint_msip_ptr(uint32_t hartid) {
    return clint_msip_ptr(hartid);
}

inline volatile uint32_t* __attribute__((const)) snrt_cluster_clint_set_ptr() {
    return cluster_clint_set_ptr(snrt_cluster_idx());
}

inline volatile uint32_t* __attribute__((const)) snrt_cluster_clint_clr_ptr() {
    return cluster_clint_clr_ptr(snrt_cluster_idx());
}

inline uint32_t __attribute__((const)) snrt_cluster_hw_barrier_addr() {
    return _snrt_cluster_hw_barrier;
}
