// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

inline uint32_t __attribute__((const)) snrt_l1_start_addr();

inline uint32_t __attribute__((const)) snrt_l1_end_addr();

inline volatile uint32_t* __attribute__((const)) snrt_clint_mutex_ptr();

inline volatile uint32_t* __attribute__((const)) snrt_clint_msip_ptr();

inline volatile uint32_t* __attribute__((const)) snrt_cluster_clint_set_ptr();

inline volatile uint32_t* __attribute__((const)) snrt_cluster_clint_clr_ptr();

inline uint32_t __attribute__((const)) snrt_cluster_hw_barrier_addr();
