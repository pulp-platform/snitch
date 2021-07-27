// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

static volatile uint32_t *sink = (void *)0xF1230000;

// int main(uint32_t core_id, uint32_t core_num , void *spm_start, void *spm_end) {
int main(int argc, char** argv) {
    
    uint32_t core_id = argc;
    uint32_t core_num = (uint32_t)((uint32_t*)argv)[0];
    void *spm_start = (void *)((uint32_t*)argv)[1];
    void *spm_end = (void *)((uint32_t*)argv)[2];

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
