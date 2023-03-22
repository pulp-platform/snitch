// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#include "occamy_base_addr.h"
#include "occamy_cfg.h"

// Auto-generated headers
#include "clint.h"
#include "occamy_soc_ctrl.h"
#include "snitch_cluster_peripheral.h"
#include "snitch_hbm_xbar_peripheral.h"
#include "snitch_quad_peripheral.h"

//===============================================================
// Reggen
//===============================================================

// Handle multireg degeneration to single register

#if CLINT_MSIP_MULTIREG_COUNT == 1
#define CLINT_MSIP_0_REG_OFFSET CLINT_MSIP_REG_OFFSET
#endif

//===============================================================
// Base addresses
//===============================================================

#define clint_msip_base (CLINT_BASE_ADDR + CLINT_MSIP_0_REG_OFFSET)

#define soc_ctrl_scratch_base \
    (SOC_CTRL_BASE_ADDR + OCCAMY_SOC_SCRATCH_0_REG_OFFSET)

#define cluster_clint_set_base               \
    (QUADRANT_0_CLUSTER_0_PERIPH_BASE_ADDR + \
     SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_SET_REG_OFFSET)
#define cluster_clint_clr_base               \
    (QUADRANT_0_CLUSTER_0_PERIPH_BASE_ADDR + \
     SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_CLEAR_REG_OFFSET)

#define cluster_hw_barrier_base              \
    (QUADRANT_0_CLUSTER_0_PERIPH_BASE_ADDR + \
     SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER_REG_OFFSET)

#define quad_cfg_reset_n_base \
    (QUAD_0_CFG_BASE_ADDR + OCCAMY_QUADRANT_S1_RESET_N_REG_OFFSET)

#define quad_cfg_clk_ena_base \
    (QUAD_0_CFG_BASE_ADDR + OCCAMY_QUADRANT_S1_CLK_ENA_REG_OFFSET)

#define quad_cfg_isolate_base \
    (QUAD_0_CFG_BASE_ADDR + OCCAMY_QUADRANT_S1_ISOLATE_REG_OFFSET)

#define quad_cfg_isolated_base \
    (QUAD_0_CFG_BASE_ADDR + OCCAMY_QUADRANT_S1_ISOLATED_REG_OFFSET)

#define quad_cfg_ro_cache_enable_base \
    (QUAD_0_CFG_BASE_ADDR + OCCAMY_QUADRANT_S1_RO_CACHE_ENABLE_REG_OFFSET)

#define quad_cfg_ro_cache_addr_rule_base \
    (QUAD_0_CFG_BASE_ADDR + OCCAMY_QUADRANT_S1_RO_START_ADDR_LOW_0_REG_OFFSET)

//===============================================================
// Replicated address spaces
//===============================================================

#define cluster_offset 0x40000

#define quadrant_cfg_offset 0x10000

inline uintptr_t translate_address(uintptr_t address, uint32_t instance,
                                   uint32_t offset) {
    return address + instance * offset;
}

inline uintptr_t translate_cluster_address(uintptr_t address,
                                           uint32_t cluster_idx) {
    return translate_address(address, cluster_idx, cluster_offset);
}

inline uintptr_t translate_quadrant_cfg_address(uintptr_t address,
                                                uint32_t quadrant_idx) {
    return translate_address(address, quadrant_idx, quadrant_cfg_offset);
}

//===============================================================
// Derived addresses
//===============================================================

inline uintptr_t cluster_clint_clr_addr(uint32_t cluster_idx) {
    return translate_cluster_address(cluster_clint_clr_base, cluster_idx);
}

inline uintptr_t cluster_clint_set_addr(uint32_t cluster_idx) {
    return translate_cluster_address(cluster_clint_set_base, cluster_idx);
}

inline uintptr_t cluster_tcdm_start_addr(uint32_t cluster_idx) {
    return translate_cluster_address(QUADRANT_0_CLUSTER_0_TCDM_BASE_ADDR,
                                     cluster_idx);
}

inline uintptr_t cluster_tcdm_end_addr(uint32_t cluster_idx) {
    return translate_cluster_address(QUADRANT_0_CLUSTER_0_PERIPH_BASE_ADDR,
                                     cluster_idx);
}

inline uintptr_t cluster_hw_barrier_addr(uint32_t cluster_idx) {
    return translate_cluster_address(cluster_hw_barrier_base, cluster_idx);
}

inline uintptr_t quad_cfg_reset_n_addr(uint32_t quadrant_idx) {
    return translate_quadrant_cfg_address(quad_cfg_reset_n_base, quadrant_idx);
}

inline uintptr_t quad_cfg_clk_ena_addr(uint32_t quadrant_idx) {
    return translate_quadrant_cfg_address(quad_cfg_clk_ena_base, quadrant_idx);
}

inline uintptr_t quad_cfg_isolate_addr(uint32_t quadrant_idx) {
    return translate_quadrant_cfg_address(quad_cfg_isolate_base, quadrant_idx);
}

inline uintptr_t quad_cfg_isolated_addr(uint32_t quadrant_idx) {
    return translate_quadrant_cfg_address(quad_cfg_isolated_base, quadrant_idx);
}

inline uintptr_t quad_cfg_ro_cache_enable_addr(uint32_t quadrant_idx) {
    return translate_quadrant_cfg_address(quad_cfg_ro_cache_enable_base,
                                          quadrant_idx);
}

inline uintptr_t quad_cfg_ro_cache_addr_rule_addr(uint32_t quadrant_idx) {
    return translate_quadrant_cfg_address(quad_cfg_ro_cache_addr_rule_base,
                                          quadrant_idx);
}

inline uintptr_t soc_ctrl_scratch_addr(uint32_t reg_idx) {
    return soc_ctrl_scratch_base +
           (reg_idx / OCCAMY_SOC_SCRATCH_SCRATCH_FIELDS_PER_REG) * 4;
}

inline uintptr_t clint_msip_addr(uint32_t hartid) {
    return clint_msip_base + (hartid / CLINT_MSIP_P_FIELDS_PER_REG) * 4;
}

//===============================================================
// Pointers
//===============================================================

// Don't mark as volatile pointer to favour compiler optimizations.
// Despite in our multicore scenario this value could change unexpectedly
// we can make some assumptions which prevent this.
// Namely, we assume that whenever this register is written to, cores
// synchronize (and execute a memory fence) before reading it. This is usually
// the case, as this register would only be written by CVA6 during
// initialization and never changed.
inline uint32_t* soc_ctrl_scratch_ptr(uint32_t reg_idx) {
    return (uint32_t*)soc_ctrl_scratch_addr(reg_idx);
}

inline volatile uint32_t* cluster_clint_clr_ptr(uint32_t cluster_idx) {
    return (volatile uint32_t*)cluster_clint_clr_addr(cluster_idx);
}

inline volatile uint32_t* cluster_clint_set_ptr(uint32_t cluster_idx) {
    return (volatile uint32_t*)cluster_clint_set_addr(cluster_idx);
}

inline volatile uint32_t* cluster_hw_barrier_ptr(uint32_t cluster_idx) {
    return (volatile uint32_t*)cluster_hw_barrier_addr(cluster_idx);
}

inline volatile uint32_t* clint_msip_ptr(uint32_t hartid) {
    return (volatile uint32_t*)clint_msip_addr(hartid);
}

inline volatile uint32_t* quad_cfg_reset_n_ptr(uint32_t quad_idx) {
    return (volatile uint32_t*)quad_cfg_reset_n_addr(quad_idx);
}

inline volatile uint32_t* quad_cfg_clk_ena_ptr(uint32_t quad_idx) {
    return (volatile uint32_t*)quad_cfg_clk_ena_addr(quad_idx);
}

inline volatile uint32_t* quad_cfg_isolate_ptr(uint32_t quad_idx) {
    return (volatile uint32_t*)quad_cfg_isolate_addr(quad_idx);
}

inline volatile uint32_t* quad_cfg_isolated_ptr(uint32_t quad_idx) {
    return (volatile uint32_t*)quad_cfg_isolated_addr(quad_idx);
}

inline volatile uint32_t* quad_cfg_ro_cache_enable_ptr(uint32_t quad_idx) {
    return (volatile uint32_t*)quad_cfg_ro_cache_enable_addr(quad_idx);
}

inline volatile uint64_t* quad_cfg_ro_cache_addr_rule_ptr(uint32_t quad_idx,
                                                          uint32_t rule_idx) {
    volatile uint64_t* p =
        (volatile uint64_t*)quad_cfg_ro_cache_addr_rule_addr(quad_idx);
    // Every address rule is made up of a 64-bit start and end address
    return p + 2 * rule_idx;
}
