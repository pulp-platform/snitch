// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
#include "snrt.h"
#include "team.h"

__thread struct snrt_team *_snrt_team_current;
const uint32_t _snrt_team_size = sizeof(struct snrt_team_root);

static uint32_t hartid() {
    uint32_t hartid;
    asm volatile ("csrr %0, mhartid" : "=r"(hartid));
    return hartid;
}

uint32_t snrt_global_core_idx() {
    return hartid() - _snrt_team_current->root->global_core_base_hartid;
}

uint32_t snrt_global_core_num() {
    return _snrt_team_current->root->global_core_num;
}

uint32_t snrt_cluster_idx() {
    return _snrt_team_current->root->cluster_idx;
}

uint32_t snrt_cluster_num() {
    return _snrt_team_current->root->cluster_num;
}

uint32_t snrt_cluster_core_idx() {
    return hartid() - _snrt_team_current->root->cluster_core_base_hartid;
}

uint32_t snrt_cluster_core_num() {
    return _snrt_team_current->root->cluster_core_num;
}
