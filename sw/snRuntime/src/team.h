// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

inline uint32_t __attribute__((const)) snrt_hartid() {
    uint32_t hartid;
    asm("csrr %0, mhartid" : "=r"(hartid));
    return hartid;
}

inline uint32_t __attribute__((const)) snrt_cluster_num() {
    return SNRT_CLUSTER_NUM;
}

inline uint32_t __attribute__((const)) snrt_cluster_core_num() {
    return SNRT_CLUSTER_CORE_NUM;
}

inline uint32_t __attribute__((const)) snrt_global_core_base_hartid() {
    return SNRT_BASE_HARTID;
}

inline uint32_t __attribute__((const)) snrt_global_core_num() {
    return snrt_cluster_num() * snrt_cluster_core_num();
}

inline uint32_t __attribute__((const)) snrt_global_core_idx() {
    return snrt_hartid() - snrt_global_core_base_hartid();
}

inline uint32_t __attribute__((const)) snrt_cluster_idx() {
    return snrt_global_core_idx() / snrt_cluster_core_num();
}

inline uint32_t __attribute__((const)) snrt_cluster_core_idx() {
    return snrt_global_core_idx() % snrt_cluster_core_num();
}

inline uint32_t __attribute__((const)) snrt_cluster_compute_core_idx() {
    return snrt_cluster_core_idx();
}

inline uint32_t __attribute__((const)) snrt_cluster_dm_core_num() {
    return SNRT_CLUSTER_DM_CORE_NUM;
}

inline uint32_t __attribute__((const)) snrt_cluster_compute_core_num() {
    return snrt_cluster_core_num() - snrt_cluster_dm_core_num();
}

inline int __attribute__((const)) snrt_is_compute_core() {
    return snrt_cluster_core_idx() < snrt_cluster_compute_core_num();
}

inline int __attribute__((const)) snrt_is_dm_core() {
    return !snrt_is_compute_core();
}
