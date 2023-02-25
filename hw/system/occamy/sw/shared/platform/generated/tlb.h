// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#include "occamy_addrmap.h"
#include "snitch_quad_peripheral.h"

static const uintptr_t QUAD_STRIDE = 0x10000;
static const uintptr_t TLB_ENTRY_STRIDE = 0x20;

// TODO: create and use TLB entry struct type

static inline void write_tlb_entry(uint32_t wide, uint32_t quad_idx,
                                   uint32_t entry_idx, uint64_t page_start,
                                   uint64_t page_end, uint64_t page_out,
                                   uint32_t read_only, uint32_t valid) {
    // Compute entry base address
    volatile uint64_t* entry_base;
    if (wide) {  // wide case
        const uintptr_t table_offs =
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_FIRST_LOW_REG_OFFSET;
        entry_base = (void*)(QUAD_0_CFG_BASE_ADDR + quad_idx * QUAD_STRIDE +
                             table_offs + entry_idx * TLB_ENTRY_STRIDE);
    } else {  // narrow case
        const uintptr_t table_offs =
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_FIRST_LOW_REG_OFFSET;
        entry_base = (void*)(QUAD_0_CFG_BASE_ADDR + quad_idx * QUAD_STRIDE +
                             table_offs + entry_idx * TLB_ENTRY_STRIDE);
    }
    // Write entry
    entry_base[0] = page_start;
    entry_base[1] = page_end;
    entry_base[2] = page_out;
    entry_base[3] = ((read_only & 1) << 1) | (valid & 1);
}

static inline void enable_tlb(uint32_t wide, uint32_t quad_idx,
                              uint32_t enable) {
    // Compute entry base address
    volatile uint32_t* enable_reg;
    if (wide) {  // wide case
        enable_reg = (void*)(QUAD_0_CFG_BASE_ADDR + quad_idx * QUAD_STRIDE +
                             OCCAMY_QUADRANT_S1_TLB_WIDE_ENABLE_REG_OFFSET);
    } else {  // narrow case
        enable_reg = (void*)(QUAD_0_CFG_BASE_ADDR + quad_idx * QUAD_STRIDE +
                             OCCAMY_QUADRANT_S1_TLB_NARROW_ENABLE_REG_OFFSET);
    }
    // Write entry
    *enable_reg = enable;
}
