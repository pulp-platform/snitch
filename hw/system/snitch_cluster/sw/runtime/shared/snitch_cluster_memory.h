// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

#include "snitch_cluster_defs.h"

//===============================================================
// Constants
//===============================================================

#define CLUSTER_CLINT_SET_ADDR  \
    (CLUSTER_PERIPH_BASE_ADDR + \
     SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_SET_REG_OFFSET)
#define CLUSTER_CLINT_CLR_ADDR  \
    (CLUSTER_PERIPH_BASE_ADDR + \
     SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_CLEAR_REG_OFFSET)

#define CLUSTER_HW_BARRIER_ADDR \
    (CLUSTER_PERIPH_BASE_ADDR + SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER_REG_OFFSET)

#define CLUSTER_PERF_COUNTER_ADDR \
    (CLUSTER_PERIPH_BASE_ADDR +   \
     SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_ENABLE_0_REG_OFFSET)

#define CLUSTER_TCDM_START_ADDR CLUSTER_TCDM_BASE_ADDR

#define CLUSTER_TCDM_END_ADDR CLUSTER_PERIPH_BASE_ADDR

//===============================================================
// snRuntime interface functions
//===============================================================

inline uint32_t __attribute__((const)) snrt_l1_start_addr() {
    return CLUSTER_TCDM_START_ADDR;
}

inline uint32_t __attribute__((const)) snrt_l1_end_addr() {
    return CLUSTER_TCDM_END_ADDR;
}

inline volatile uint32_t* __attribute__((const)) snrt_cluster_clint_set_ptr() {
    return (uint32_t*)CLUSTER_CLINT_SET_ADDR;
}

inline volatile uint32_t* __attribute__((const)) snrt_cluster_clint_clr_ptr() {
    return (uint32_t*)CLUSTER_CLINT_CLR_ADDR;
}

inline uint32_t __attribute__((const)) snrt_cluster_hw_barrier_addr() {
    return CLUSTER_HW_BARRIER_ADDR;
}

inline uint32_t __attribute__((const)) snrt_cluster_perf_counters_addr() {
    return CLUSTER_PERF_COUNTER_ADDR;
}

inline volatile uint32_t* __attribute__((const)) snrt_zero_memory_ptr() {
    return (uint32_t*)CLUSTER_ZERO_MEM_START_ADDR;
}
