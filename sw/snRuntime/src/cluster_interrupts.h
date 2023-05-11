// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * @brief Write mask to the cluster-local interrupt set register
 * @param mask set bit at X sets the interrupt of hart X
 */
inline void snrt_int_cluster_set(uint32_t mask) {
    *(snrt_cluster_clint_set_ptr()) = mask;
}

/**
 * @brief Write mask to the cluster-local interrupt clear register
 * @param mask set bit at X clears the interrupt of hart X
 */
inline void snrt_int_cluster_clr(uint32_t mask) {
    *(snrt_cluster_clint_clr_ptr()) = mask;
}

inline void snrt_int_clr_mcip() {
    snrt_int_cluster_clr(1 << snrt_cluster_core_idx());
}

inline void snrt_int_set_mcip() {
    snrt_int_cluster_set(1 << snrt_cluster_core_idx());
}
