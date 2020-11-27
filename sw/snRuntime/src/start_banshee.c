// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
#include "snrt.h"
#include "team.h"

extern const uint32_t _snrt_banshee_cluster_core_num;
extern const uint32_t _snrt_banshee_cluster_base_hartid;
extern const uint32_t _snrt_banshee_cluster_num;
extern const uint32_t _snrt_banshee_cluster_id;
void * const _snrt_banshee_global_start = (void*)0x90000000;
void * const _snrt_banshee_global_end = (void*)0x100000000;

const uint32_t snrt_stack_size __attribute__((weak)) = 10;

void _snrt_init_team(uint32_t cluster_core_id, uint32_t cluster_core_num, void *spm_start, void *spm_end, struct snrt_team_root *team) {
    team->base.root = team;
    team->global_core_base_hartid =
        _snrt_banshee_cluster_base_hartid -
        _snrt_banshee_cluster_id *
        _snrt_banshee_cluster_core_num;
    team->global_core_num =
        _snrt_banshee_cluster_num *
        _snrt_banshee_cluster_core_num;
    team->cluster_idx = _snrt_banshee_cluster_id;
    team->cluster_num = _snrt_banshee_cluster_num;
    team->cluster_core_base_hartid = _snrt_banshee_cluster_base_hartid;
    team->cluster_core_num = _snrt_banshee_cluster_core_num;
    team->global_mem.start = _snrt_banshee_global_start;
    team->global_mem.end = _snrt_banshee_global_end;
    team->cluster_mem.start = spm_start;
    team->cluster_mem.end = spm_end;

    _snrt_team_current = &team->base;
}
