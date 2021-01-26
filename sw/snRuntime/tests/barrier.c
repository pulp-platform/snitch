// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
#include <snrt.h>

static volatile uint32_t *sink = (void *)0xF1230000;

int main(uint32_t core_id, uint32_t core_num, void *spm_start, void *spm_end) {
    volatile uint32_t *x = spm_start + 4;
    if (core_id == 0) {
        *x = 0;
    }
    for (uint32_t i = 0; i < core_num; i++) {
        snrt_barrier();
        if (i == core_id) {
            *sink = core_id;
            *x += 1;
        }
    }
    snrt_barrier();
    return core_id == 0 ? core_num -= *x : 0;
}
