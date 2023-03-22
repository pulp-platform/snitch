// Generated register defines for occamy_quadrant_s1

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

// Isolation status of S1 quadrant and port
#define OCCAMY_QUADRANT_S1_ISOLATED_REG_OFFSET 0xc
#define OCCAMY_QUADRANT_S1_ISOLATED_NARROW_IN_BIT 0
#define OCCAMY_QUADRANT_S1_ISOLATED_NARROW_OUT_BIT 1
#define OCCAMY_QUADRANT_S1_ISOLATED_WIDE_IN_BIT 2
#define OCCAMY_QUADRANT_S1_ISOLATED_WIDE_OUT_BIT 3

// Enable read-only cache of quadrant.
#define OCCAMY_QUADRANT_S1_RO_CACHE_ENABLE_REG_OFFSET 0x10
#define OCCAMY_QUADRANT_S1_RO_CACHE_ENABLE_ENABLE_BIT 0

// Flush read-only cache.
#define OCCAMY_QUADRANT_S1_RO_CACHE_FLUSH_REG_OFFSET 0x14
#define OCCAMY_QUADRANT_S1_RO_CACHE_FLUSH_FLUSH_BIT 0

// Enable TLB on wide interface of quadrant.
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENABLE_REG_OFFSET 0x18
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENABLE_ENABLE_BIT 0

// Enable TLB on narrow interface of quadrant.
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENABLE_REG_OFFSET 0x1c
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENABLE_ENABLE_BIT 0

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

// narrow TLB entry 0: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_FIRST_LOW_REG_OFFSET 0x800

// narrow TLB entry 0: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_FIRST_HIGH_REG_OFFSET 0x804
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                  \
        .mask =                                                                             \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                            \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// narrow TLB entry 0: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_LAST_LOW_REG_OFFSET 0x808

// narrow TLB entry 0: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_LAST_HIGH_REG_OFFSET 0x80c
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// narrow TLB entry 0: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEOUT_LOW_REG_OFFSET 0x810

// narrow TLB entry 0: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEOUT_HIGH_REG_OFFSET 0x814
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                        \
        .mask =                                                                   \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                  \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// narrow TLB entry 0: Flags
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_FLAGS_REG_OFFSET 0x818
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_0_FLAGS_READ_ONLY_BIT 1

// narrow TLB entry 1: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_FIRST_LOW_REG_OFFSET 0x820

// narrow TLB entry 1: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_FIRST_HIGH_REG_OFFSET 0x824
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                  \
        .mask =                                                                             \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                            \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// narrow TLB entry 1: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_LAST_LOW_REG_OFFSET 0x828

// narrow TLB entry 1: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_LAST_HIGH_REG_OFFSET 0x82c
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// narrow TLB entry 1: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEOUT_LOW_REG_OFFSET 0x830

// narrow TLB entry 1: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEOUT_HIGH_REG_OFFSET 0x834
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                        \
        .mask =                                                                   \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                  \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// narrow TLB entry 1: Flags
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_FLAGS_REG_OFFSET 0x838
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_1_FLAGS_READ_ONLY_BIT 1

// narrow TLB entry 2: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_FIRST_LOW_REG_OFFSET 0x840

// narrow TLB entry 2: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_FIRST_HIGH_REG_OFFSET 0x844
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                  \
        .mask =                                                                             \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                            \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// narrow TLB entry 2: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_LAST_LOW_REG_OFFSET 0x848

// narrow TLB entry 2: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_LAST_HIGH_REG_OFFSET 0x84c
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// narrow TLB entry 2: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEOUT_LOW_REG_OFFSET 0x850

// narrow TLB entry 2: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEOUT_HIGH_REG_OFFSET 0x854
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                        \
        .mask =                                                                   \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                  \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// narrow TLB entry 2: Flags
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_FLAGS_REG_OFFSET 0x858
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_2_FLAGS_READ_ONLY_BIT 1

// narrow TLB entry 3: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_FIRST_LOW_REG_OFFSET 0x860

// narrow TLB entry 3: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_FIRST_HIGH_REG_OFFSET 0x864
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                  \
        .mask =                                                                             \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                            \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// narrow TLB entry 3: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_LAST_LOW_REG_OFFSET 0x868

// narrow TLB entry 3: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_LAST_HIGH_REG_OFFSET 0x86c
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// narrow TLB entry 3: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEOUT_LOW_REG_OFFSET 0x870

// narrow TLB entry 3: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEOUT_HIGH_REG_OFFSET 0x874
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                        \
        .mask =                                                                   \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                  \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// narrow TLB entry 3: Flags
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_FLAGS_REG_OFFSET 0x878
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_3_FLAGS_READ_ONLY_BIT 1

// narrow TLB entry 4: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_FIRST_LOW_REG_OFFSET 0x880

// narrow TLB entry 4: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_FIRST_HIGH_REG_OFFSET 0x884
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                  \
        .mask =                                                                             \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                            \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// narrow TLB entry 4: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_LAST_LOW_REG_OFFSET 0x888

// narrow TLB entry 4: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_LAST_HIGH_REG_OFFSET 0x88c
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// narrow TLB entry 4: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEOUT_LOW_REG_OFFSET 0x890

// narrow TLB entry 4: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEOUT_HIGH_REG_OFFSET 0x894
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                        \
        .mask =                                                                   \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                  \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// narrow TLB entry 4: Flags
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_FLAGS_REG_OFFSET 0x898
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_4_FLAGS_READ_ONLY_BIT 1

// narrow TLB entry 5: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_FIRST_LOW_REG_OFFSET 0x8a0

// narrow TLB entry 5: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_FIRST_HIGH_REG_OFFSET 0x8a4
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                  \
        .mask =                                                                             \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                            \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// narrow TLB entry 5: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_LAST_LOW_REG_OFFSET 0x8a8

// narrow TLB entry 5: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_LAST_HIGH_REG_OFFSET 0x8ac
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// narrow TLB entry 5: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEOUT_LOW_REG_OFFSET 0x8b0

// narrow TLB entry 5: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEOUT_HIGH_REG_OFFSET 0x8b4
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                        \
        .mask =                                                                   \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                  \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// narrow TLB entry 5: Flags
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_FLAGS_REG_OFFSET 0x8b8
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_5_FLAGS_READ_ONLY_BIT 1

// narrow TLB entry 6: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_FIRST_LOW_REG_OFFSET 0x8c0

// narrow TLB entry 6: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_FIRST_HIGH_REG_OFFSET 0x8c4
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                  \
        .mask =                                                                             \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                            \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// narrow TLB entry 6: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_LAST_LOW_REG_OFFSET 0x8c8

// narrow TLB entry 6: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_LAST_HIGH_REG_OFFSET 0x8cc
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// narrow TLB entry 6: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEOUT_LOW_REG_OFFSET 0x8d0

// narrow TLB entry 6: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEOUT_HIGH_REG_OFFSET 0x8d4
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                        \
        .mask =                                                                   \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                  \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// narrow TLB entry 6: Flags
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_FLAGS_REG_OFFSET 0x8d8
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_6_FLAGS_READ_ONLY_BIT 1

// narrow TLB entry 7: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_FIRST_LOW_REG_OFFSET 0x8e0

// narrow TLB entry 7: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_FIRST_HIGH_REG_OFFSET 0x8e4
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                  \
        .mask =                                                                             \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                            \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// narrow TLB entry 7: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_LAST_LOW_REG_OFFSET 0x8e8

// narrow TLB entry 7: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_LAST_HIGH_REG_OFFSET 0x8ec
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// narrow TLB entry 7: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEOUT_LOW_REG_OFFSET 0x8f0

// narrow TLB entry 7: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEOUT_HIGH_REG_OFFSET 0x8f4
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                        \
        .mask =                                                                   \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                  \
            OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// narrow TLB entry 7: Flags
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_FLAGS_REG_OFFSET 0x8f8
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_NARROW_ENTRY_7_FLAGS_READ_ONLY_BIT 1

// wide TLB entry 0: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_FIRST_LOW_REG_OFFSET 0x1000

// wide TLB entry 0: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_FIRST_HIGH_REG_OFFSET 0x1004
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// wide TLB entry 0: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_LAST_LOW_REG_OFFSET 0x1008

// wide TLB entry 0: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_LAST_HIGH_REG_OFFSET 0x100c
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                              \
        .mask =                                                                         \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                        \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// wide TLB entry 0: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEOUT_LOW_REG_OFFSET 0x1010

// wide TLB entry 0: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEOUT_HIGH_REG_OFFSET 0x1014
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                      \
        .mask =                                                                 \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// wide TLB entry 0: Flags
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_FLAGS_REG_OFFSET 0x1018
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_0_FLAGS_READ_ONLY_BIT 1

// wide TLB entry 1: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_FIRST_LOW_REG_OFFSET 0x1020

// wide TLB entry 1: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_FIRST_HIGH_REG_OFFSET 0x1024
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// wide TLB entry 1: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_LAST_LOW_REG_OFFSET 0x1028

// wide TLB entry 1: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_LAST_HIGH_REG_OFFSET 0x102c
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                              \
        .mask =                                                                         \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                        \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// wide TLB entry 1: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEOUT_LOW_REG_OFFSET 0x1030

// wide TLB entry 1: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEOUT_HIGH_REG_OFFSET 0x1034
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                      \
        .mask =                                                                 \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// wide TLB entry 1: Flags
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_FLAGS_REG_OFFSET 0x1038
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_1_FLAGS_READ_ONLY_BIT 1

// wide TLB entry 2: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_FIRST_LOW_REG_OFFSET 0x1040

// wide TLB entry 2: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_FIRST_HIGH_REG_OFFSET 0x1044
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// wide TLB entry 2: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_LAST_LOW_REG_OFFSET 0x1048

// wide TLB entry 2: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_LAST_HIGH_REG_OFFSET 0x104c
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                              \
        .mask =                                                                         \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                        \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// wide TLB entry 2: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEOUT_LOW_REG_OFFSET 0x1050

// wide TLB entry 2: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEOUT_HIGH_REG_OFFSET 0x1054
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                      \
        .mask =                                                                 \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// wide TLB entry 2: Flags
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_FLAGS_REG_OFFSET 0x1058
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_2_FLAGS_READ_ONLY_BIT 1

// wide TLB entry 3: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_FIRST_LOW_REG_OFFSET 0x1060

// wide TLB entry 3: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_FIRST_HIGH_REG_OFFSET 0x1064
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// wide TLB entry 3: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_LAST_LOW_REG_OFFSET 0x1068

// wide TLB entry 3: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_LAST_HIGH_REG_OFFSET 0x106c
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                              \
        .mask =                                                                         \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                        \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// wide TLB entry 3: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEOUT_LOW_REG_OFFSET 0x1070

// wide TLB entry 3: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEOUT_HIGH_REG_OFFSET 0x1074
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                      \
        .mask =                                                                 \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// wide TLB entry 3: Flags
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_FLAGS_REG_OFFSET 0x1078
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_3_FLAGS_READ_ONLY_BIT 1

// wide TLB entry 4: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_FIRST_LOW_REG_OFFSET 0x1080

// wide TLB entry 4: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_FIRST_HIGH_REG_OFFSET 0x1084
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// wide TLB entry 4: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_LAST_LOW_REG_OFFSET 0x1088

// wide TLB entry 4: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_LAST_HIGH_REG_OFFSET 0x108c
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                              \
        .mask =                                                                         \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                        \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// wide TLB entry 4: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEOUT_LOW_REG_OFFSET 0x1090

// wide TLB entry 4: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEOUT_HIGH_REG_OFFSET 0x1094
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                      \
        .mask =                                                                 \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// wide TLB entry 4: Flags
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_FLAGS_REG_OFFSET 0x1098
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_4_FLAGS_READ_ONLY_BIT 1

// wide TLB entry 5: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_FIRST_LOW_REG_OFFSET 0x10a0

// wide TLB entry 5: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_FIRST_HIGH_REG_OFFSET 0x10a4
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// wide TLB entry 5: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_LAST_LOW_REG_OFFSET 0x10a8

// wide TLB entry 5: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_LAST_HIGH_REG_OFFSET 0x10ac
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                              \
        .mask =                                                                         \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                        \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// wide TLB entry 5: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEOUT_LOW_REG_OFFSET 0x10b0

// wide TLB entry 5: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEOUT_HIGH_REG_OFFSET 0x10b4
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                      \
        .mask =                                                                 \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// wide TLB entry 5: Flags
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_FLAGS_REG_OFFSET 0x10b8
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_5_FLAGS_READ_ONLY_BIT 1

// wide TLB entry 6: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_FIRST_LOW_REG_OFFSET 0x10c0

// wide TLB entry 6: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_FIRST_HIGH_REG_OFFSET 0x10c4
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// wide TLB entry 6: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_LAST_LOW_REG_OFFSET 0x10c8

// wide TLB entry 6: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_LAST_HIGH_REG_OFFSET 0x10cc
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                              \
        .mask =                                                                         \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                        \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// wide TLB entry 6: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEOUT_LOW_REG_OFFSET 0x10d0

// wide TLB entry 6: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEOUT_HIGH_REG_OFFSET 0x10d4
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                      \
        .mask =                                                                 \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// wide TLB entry 6: Flags
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_FLAGS_REG_OFFSET 0x10d8
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_6_FLAGS_READ_ONLY_BIT 1

// wide TLB entry 7: Lower 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_FIRST_LOW_REG_OFFSET 0x10e0

// wide TLB entry 7: Upper 32-bit of first page number of input range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_FIRST_HIGH_REG_OFFSET 0x10e4
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                                \
        .mask =                                                                           \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_MASK, \
        .index =                                                                          \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_FIRST_HIGH_PAGEIN_FIRST_HIGH_OFFSET})

// wide TLB entry 7: Lower 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_LAST_LOW_REG_OFFSET 0x10e8

// wide TLB entry 7: Upper 32-bit of last page (inclusive) number of input
// range
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_LAST_HIGH_REG_OFFSET 0x10ec
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK \
    0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET \
    0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_FIELD     \
    ((bitfield_field32_t){                                                              \
        .mask =                                                                         \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_MASK, \
        .index =                                                                        \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEIN_LAST_HIGH_PAGEIN_LAST_HIGH_OFFSET})

// wide TLB entry 7: Lower 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEOUT_LOW_REG_OFFSET 0x10f0

// wide TLB entry 7: Upper 32-bit of output base page
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEOUT_HIGH_REG_OFFSET 0x10f4
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK 0xf
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_FIELD     \
    ((bitfield_field32_t){                                                      \
        .mask =                                                                 \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_MASK, \
        .index =                                                                \
            OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_PAGEOUT_HIGH_PAGEOUT_HIGH_OFFSET})

// wide TLB entry 7: Flags
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_FLAGS_REG_OFFSET 0x10f8
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_FLAGS_VALID_BIT 0
#define OCCAMY_QUADRANT_S1_TLB_WIDE_ENTRY_7_FLAGS_READ_ONLY_BIT 1

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _OCCAMY_QUADRANT_S1_REG_DEFS_
        // End generated register defines for occamy_quadrant_s1