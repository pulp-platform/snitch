// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

int main(uint32_t core_id, uint32_t core_num) {
    volatile uint8_t *p = (uint8_t *)0x100000;
    volatile uint32_t x;
    if (!core_id) {
        *p = 3;
    }
    pulp_barrier();
    x = *(p + 4);
    *(p + 1) = x;
    pulp_barrier();
    if (!core_id) {
        x = *(p + 4);
    }
    return !core_id ? 2 * core_num - x : 0;
}
