// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "snrt.h"

// Must match with `snitch_cluster_peripheral`
#define NUM_PERF_COUNTERS 2

typedef union {
    uint32_t value __attribute__((aligned(8)));
} perf_reg32_t;

typedef struct {
    volatile perf_reg32_t enable[NUM_PERF_COUNTERS];
    volatile perf_reg32_t
        hart_select;  // multireg is compacted into one register
    volatile perf_reg32_t perf_counter[NUM_PERF_COUNTERS];
} perf_reg_t;

/// Different perf counters
enum snrt_perf_cnt {
    SNRT_PERF_CNT0 = 0,
    SNRT_PERF_CNT1 = 1,
};

/// Different types of performance counters
enum snrt_perf_cnt_type {
    SNRT_PERF_CNT_CYCLES,
    SNRT_PERF_CNT_TCDM_ACCESSED,
    SNRT_PERF_CNT_TCDM_CONGESTED,
    SNRT_PERF_CNT_ISSUE_FPU,
    SNRT_PERF_CNT_ISSUE_FPU_SEQ,
    SNRT_PERF_CNT_ISSUE_ISSUE_CORE_TO_FPU,
    SNRT_PERF_CNT_DMA_AW_STALL,
    SNRT_PERF_CNT_DMA_AR_STALL,
    SNRT_PERF_CNT_DMA_R_STALL,
    SNRT_PERF_CNT_DMA_W_STALL,
    SNRT_PERF_CNT_DMA_BUF_W_STALL,
    SNRT_PERF_CNT_DMA_BUF_R_STALL,
    SNRT_PERF_CNT_DMA_AW_VALID,
    SNRT_PERF_CNT_DMA_AW_READY,
    SNRT_PERF_CNT_DMA_AW_DONE,
    SNRT_PERF_CNT_DMA_AW_BW,
    SNRT_PERF_CNT_DMA_AR_VALID,
    SNRT_PERF_CNT_DMA_AR_READY,
    SNRT_PERF_CNT_DMA_AR_DONE,
    SNRT_PERF_CNT_DMA_AR_BW,
    SNRT_PERF_CNT_DMA_R_VALID,
    SNRT_PERF_CNT_DMA_R_READY,
    SNRT_PERF_CNT_DMA_R_DONE,
    SNRT_PERF_CNT_DMA_R_BW,
    SNRT_PERF_CNT_DMA_W_VALID,
    SNRT_PERF_CNT_DMA_W_READY,
    SNRT_PERF_CNT_DMA_W_DONE,
    SNRT_PERF_CNT_DMA_W_BW,
    SNRT_PERF_CNT_DMA_B_VALID,
    SNRT_PERF_CNT_DMA_B_READY,
    SNRT_PERF_CNT_DMA_B_DONE,
    SNRT_PERF_CNT_DMA_BUSY
};

void snrt_start_perf_counter(enum snrt_perf_cnt perf_cnt,
                                    enum snrt_perf_cnt_type perf_cnt_type,
                                    uint32_t hart_id);
void snrt_stop_perf_counter(enum snrt_perf_cnt perf_cnt);
void snrt_reset_perf_counter(enum snrt_perf_cnt);
uint32_t snrt_get_perf_counter(enum snrt_perf_cnt perf_cnt);
