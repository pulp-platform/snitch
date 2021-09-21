// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"
#include "team.h"

extern const uint32_t _snrt_banshee_cluster_core_num;
extern const uint32_t _snrt_banshee_cluster_base_hartid;
extern const uint32_t _snrt_banshee_cluster_num;
extern const uint32_t _snrt_banshee_cluster_id;
extern const uint32_t wakeup_reg;
uint64_t const _snrt_banshee_global_start = (uint64_t)0x90000000;
uint64_t const _snrt_banshee_global_end = (uint64_t)0x100000000;

const uint32_t snrt_stack_size __attribute__((weak, section(".rodata"))) = 10;

void _snrt_init_team(uint32_t cluster_core_id, uint32_t cluster_core_num,
                     void *spm_start, void *spm_end, void *device_tree,
                     struct snrt_team_root *team) {
    (void)cluster_core_id;
    (void)cluster_core_num;
    (void)device_tree;

    team->base.root = team;
    team->global_core_base_hartid =
        _snrt_banshee_cluster_base_hartid -
        _snrt_banshee_cluster_id * _snrt_banshee_cluster_core_num;
    team->global_core_num =
        _snrt_banshee_cluster_num * _snrt_banshee_cluster_core_num;
    team->cluster_idx = _snrt_banshee_cluster_id;
    team->cluster_num = _snrt_banshee_cluster_num;
    team->cluster_core_base_hartid = _snrt_banshee_cluster_base_hartid;
    team->cluster_core_num = _snrt_banshee_cluster_core_num;
    team->global_mem.start = _snrt_banshee_global_start;
    team->global_mem.end = _snrt_banshee_global_end;
    team->cluster_mem.start = (uint64_t)spm_start;
    team->cluster_mem.end = (uint64_t)spm_end;

    // TLS caches of frequently used data
    _snrt_team_current = &team->base;
    _snrt_core_idx =
        (snrt_hartid() - _snrt_team_current->root->cluster_core_base_hartid) %
        _snrt_team_current->root->cluster_core_num;

    // init peripherals
    team->peripherals.clint = (uint32_t *)0xffff0000;
    team->peripherals.wakeup = (uint32_t *)0x40000028;
    team->peripherals.cl_clint = (uint32_t *)0x40000060;

    // Init allocator
    snrt_alloc_init(team);
    snrt_int_init(team);
}

// Provide an implementation for putchar.
void snrt_putchar(char character) {
    *(volatile uint32_t *)0xF00B8000 = character;
}
