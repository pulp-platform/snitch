// Generated register defines for Occamy_quadrant_s1

// Copyright information found in source file:
// Copyright 2020 ETH Zurich and University of Bologna.

// Licensing information found in source file:
// Licensed under Solderpad Hardware License, Version 0.51, see LICENSE for
// details. SPDX-License-Identifier: SHL-0.51

#ifndef _OCCAMY_QUADRANT_S1_REG_DEFS_
#define _OCCAMY_QUADRANT_S1_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define OCCAMY_QUADRANT_S1_PARAM_REG_WIDTH 32

// Quadrant-internal clock gate enable
#define OCCAMY_QUADRANT_S1_CLK_ENA_REG_OFFSET 0x0
#define OCCAMY_QUADRANT_S1_CLK_ENA_CLK_ENA_BIT 0

// Quadrant-internal asynchronous active-low reset
#define OCCAMY_QUADRANT_S1_RESET_N_REG_OFFSET 0x4
#define OCCAMY_QUADRANT_S1_RESET_N_RESET_N_BIT 0

// Isolate ports of given quadrant.
#define OCCAMY_QUADRANT_S1_ISOLATE_REG_OFFSET 0x8
#define OCCAMY_QUADRANT_S1_ISOLATE_NARROW_IN_BIT 0
#define OCCAMY_QUADRANT_S1_ISOLATE_NARROW_OUT_BIT 1
#define OCCAMY_QUADRANT_S1_ISOLATE_WIDE_IN_BIT 2
#define OCCAMY_QUADRANT_S1_ISOLATE_WIDE_OUT_BIT 3
#define OCCAMY_QUADRANT_S1_ISOLATE_HBI_OUT_BIT 4

// Isolation status of S1 quadrant and port
#define OCCAMY_QUADRANT_S1_ISOLATED_REG_OFFSET 0xc
#define OCCAMY_QUADRANT_S1_ISOLATED_NARROW_IN_BIT 0
#define OCCAMY_QUADRANT_S1_ISOLATED_NARROW_OUT_BIT 1
#define OCCAMY_QUADRANT_S1_ISOLATED_WIDE_IN_BIT 2
#define OCCAMY_QUADRANT_S1_ISOLATED_WIDE_OUT_BIT 3
#define OCCAMY_QUADRANT_S1_ISOLATED_HBI_OUT_BIT 4

// Enable read-only cache of quadrant.
#define OCCAMY_QUADRANT_S1_RO_CACHE_ENABLE_REG_OFFSET 0x10
#define OCCAMY_QUADRANT_S1_RO_CACHE_ENABLE_ENABLE_BIT 0

// Read-only cache start address low
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_LOW_0_REG_OFFSET 0x100

// Read-only cache start address high
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_0_REG_OFFSET 0x104
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                              \
        .mask = OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_0_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_LOW_0_REG_OFFSET 0x108

// Read-only cache end address high
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_0_REG_OFFSET 0x10c
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                            \
        .mask = OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_0_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_LOW_1_REG_OFFSET 0x110

// Read-only cache start address high
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_1_REG_OFFSET 0x114
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                              \
        .mask = OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_1_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_LOW_1_REG_OFFSET 0x118

// Read-only cache end address high
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_1_REG_OFFSET 0x11c
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                            \
        .mask = OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_1_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_LOW_2_REG_OFFSET 0x120

// Read-only cache start address high
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_2_REG_OFFSET 0x124
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                              \
        .mask = OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_2_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_LOW_2_REG_OFFSET 0x128

// Read-only cache end address high
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_2_REG_OFFSET 0x12c
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                            \
        .mask = OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_2_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_LOW_3_REG_OFFSET 0x130

// Read-only cache start address high
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_3_REG_OFFSET 0x134
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                              \
        .mask = OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_3_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_LOW_3_REG_OFFSET 0x138

// Read-only cache end address high
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_3_REG_OFFSET 0x13c
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                            \
        .mask = OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_3_ADDR_HIGH_OFFSET})

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _OCCAMY_QUADRANT_S1_REG_DEFS_
        // End generated register defines for Occamy_quadrant_s1