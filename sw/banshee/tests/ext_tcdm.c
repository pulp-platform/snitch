// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

int main(uint32_t core_id, uint32_t core_num) {
    volatile uint8_t *p_cluster_id = (uint8_t *)0x40000050;
    switch(*p_cluster_id) {
        case 0: {
                    volatile uint8_t *p_tcm_1 = (uint8_t *)0x11000;
                    *p_tcm_1 = 23;
                }
                break;
        case 1: {
                    volatile uint8_t *p_tcm_1 = (uint8_t *)0x1000;
                    volatile uint8_t *p_tcm_2 = (uint8_t *)0x5FFFF;
                    while (*p_tcm_1 != 23 || *p_tcm_2 != 42) {}
                }
                break;
        default: {
                     volatile uint8_t *p_tcm_2 = (uint8_t *)0x2FFFF;
                     *p_tcm_2 = 42;
                 }
                 break;
    }
    return 0;
}
