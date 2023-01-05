// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

// TLS copy of frequently used data that doesn't change at runtime
__thread struct snrt_team *_snrt_team_current;

const uint32_t _snrt_team_size __attribute__((section(".rodata"))) =
    sizeof(struct snrt_team_root);

uint32_t _snrt_barrier_reg_ptr() {
    return _snrt_team_current->root->barrier_reg_ptr;
}

snrt_slice_t snrt_global_memory() {
    return _snrt_team_current->root->global_mem;
}

snrt_slice_t snrt_cluster_memory() {
    return _snrt_team_current->root->cluster_mem;
}

snrt_slice_t snrt_zero_memory() { return _snrt_team_current->root->zero_mem; }

void snrt_wakeup(uint32_t mask) { *snrt_peripherals()->wakeup = mask; }
