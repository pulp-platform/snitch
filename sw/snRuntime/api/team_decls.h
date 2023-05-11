// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

inline uint32_t __attribute__((const)) snrt_hartid();
inline uint32_t __attribute__((const)) snrt_cluster_num();
inline uint32_t __attribute__((const)) snrt_cluster_core_num();
inline uint32_t __attribute__((const)) snrt_global_core_base_hartid();
inline uint32_t __attribute__((const)) snrt_global_core_num();
inline uint32_t __attribute__((const)) snrt_global_core_idx();
inline uint32_t __attribute__((const)) snrt_cluster_idx();
inline uint32_t __attribute__((const)) snrt_cluster_core_idx();
inline uint32_t __attribute__((const)) snrt_cluster_dm_core_num();
inline uint32_t __attribute__((const)) snrt_cluster_compute_core_num();
inline int __attribute__((const)) snrt_is_compute_core();
inline int __attribute__((const)) snrt_is_dm_core();