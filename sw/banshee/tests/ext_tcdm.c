// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

int main(uint32_t core_id, uint32_t core_num) {
    volatile uint8_t *p_ext = (uint8_t *)0x30001;
    volatile uint8_t *p = (uint8_t *)0x00001;
    *p = 42;
    return !(*p_ext == 42);
}
