// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "snrt.h"

/// Different perf counters
// Must match with `snitch_cluster_peripheral`
enum snrt_perf_cnt {
    SNRT_PERF_CNT0,
    SNRT_PERF_CNT1,
    SNRT_PERF_CNT2,
    SNRT_PERF_CNT3,
    SNRT_PERF_CNT4,
    SNRT_PERF_CNT5,
    SNRT_PERF_CNT6,
    SNRT_PERF_CNT7,
    SNRT_PERF_CNT8,
    SNRT_PERF_CNT9,
    SNRT_PERF_CNT10,
    SNRT_PERF_CNT11,
    SNRT_PERF_CNT12,
    SNRT_PERF_CNT13,
    SNRT_PERF_CNT14,
    SNRT_PERF_CNT15,
    SNRT_PERF_N_CNT,
};

/// Different types of performance counters
enum snrt_perf_cnt_type {
    SNRT_PERF_CNT_CYCLES,
    SNRT_PERF_CNT_TCDM_ACCESSED,
    SNRT_PERF_CNT_TCDM_CONGESTED,
    SNRT_PERF_CNT_ISSUE_FPU,
    SNRT_PERF_CNT_ISSUE_FPU_SEQ,
    SNRT_PERF_CNT_ISSUE_CORE_TO_FPU,
    SNRT_PERF_CNT_RETIRED_INSTR,
    SNRT_PERF_CNT_RETIRED_LOAD,
    SNRT_PERF_CNT_RETIRED_I,
    SNRT_PERF_CNT_RETIRED_ACC,
    SNRT_PERF_CNT_DMA_AW_STALL,
    SNRT_PERF_CNT_DMA_AR_STALL,
    SNRT_PERF_CNT_DMA_R_STALL,
    SNRT_PERF_CNT_DMA_W_STALL,
    SNRT_PERF_CNT_DMA_BUF_W_STALL,
    SNRT_PERF_CNT_DMA_BUF_R_STALL,
    SNRT_PERF_CNT_DMA_AW_DONE,
    SNRT_PERF_CNT_DMA_AW_BW,
    SNRT_PERF_CNT_DMA_AR_DONE,
    SNRT_PERF_CNT_DMA_AR_BW,
    SNRT_PERF_CNT_DMA_R_DONE,
    SNRT_PERF_CNT_DMA_R_BW,
    SNRT_PERF_CNT_DMA_W_DONE,
    SNRT_PERF_CNT_DMA_W_BW,
    SNRT_PERF_CNT_DMA_B_DONE,
    SNRT_PERF_CNT_DMA_BUSY,
    SNRT_PERF_CNT_ICACHE_MISS,
    SNRT_PERF_CNT_ICACHE_HIT,
    SNRT_PERF_CNT_ICACHE_PREFETCH,
    SNRT_PERF_CNT_ICACHE_DOUBLE_HIT,
    SNRT_PERF_CNT_ICACHE_STALL,
};

typedef union {
    uint32_t value __attribute__((aligned(8)));
} perf_reg32_t;

typedef struct {
    volatile perf_reg32_t enable[SNRT_PERF_N_CNT];
    volatile perf_reg32_t hart_select[SNRT_PERF_N_CNT];
    volatile perf_reg32_t perf_counter[SNRT_PERF_N_CNT];
} perf_reg_t;

void snrt_start_perf_counter(enum snrt_perf_cnt perf_cnt,
                             enum snrt_perf_cnt_type perf_cnt_type,
                             uint32_t hart_id);
void snrt_stop_perf_counter(enum snrt_perf_cnt perf_cnt);
void snrt_reset_perf_counter(enum snrt_perf_cnt);
uint32_t snrt_get_perf_counter(enum snrt_perf_cnt perf_cnt);
