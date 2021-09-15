// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "perf_cnt.h"

// Enable a specific perf_counter
void snrt_start_perf_counter(enum snrt_perf_cnt perf_cnt,
                             enum snrt_perf_cnt_type perf_cnt_type,
                             uint32_t hart_id) {
    perf_reg_t *perf_reg = (void *)snrt_peripherals()->perf_counters;
    perf_reg->hart_select[perf_cnt].value |= hart_id;
    perf_reg->enable[perf_cnt].value = (0x1 << perf_cnt_type);
}

// Stops the counter but does not reset it
void snrt_stop_perf_counter(enum snrt_perf_cnt perf_cnt) {
    perf_reg_t *perf_reg = (void *)snrt_peripherals()->perf_counters;
    perf_reg->enable[perf_cnt].value = 0x0;
}

// Resets the counter completely
void snrt_reset_perf_counter(enum snrt_perf_cnt perf_cnt) {
    perf_reg_t *perf_reg = (void *)snrt_peripherals()->perf_counters;
    perf_reg->enable[perf_cnt].value = 0x0;
    perf_reg->hart_select[perf_cnt].value = 0x0;
    perf_reg->perf_counter[perf_cnt].value = 0x0;
}

// Get counter of specified perf_counter
uint32_t snrt_get_perf_counter(enum snrt_perf_cnt perf_cnt) {
    perf_reg_t *perf_reg = (void *)snrt_peripherals()->perf_counters;
    return (uint32_t)perf_reg->perf_counter[perf_cnt].value;
}
