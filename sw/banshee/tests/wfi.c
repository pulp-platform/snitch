// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

int main(uint32_t core_id, uint32_t core_num) {
    volatile uint32_t *x = (void *)&l1_alloc_base;
    volatile uint32_t *wake_up = (void *)&wake_up_reg;
    // Get global core_id
    if (core_id == 0) {
        *x = 1;
        *wake_up = (core_id + 1) % core_num;
    } else {
        asm volatile("wfi");
        *x += 1;
        *wake_up = (core_id + 1) % core_num;
    }
    asm volatile("wfi");
    return core_id == 0 ? core_num -= *x : 0;
}
