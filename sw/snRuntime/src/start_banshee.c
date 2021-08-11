// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"
#include "team.h"

extern const uint32_t _snrt_banshee_cluster_core_num;
extern const uint32_t _snrt_banshee_cluster_base_hartid;
extern const uint32_t _snrt_banshee_cluster_num;
extern const uint32_t _snrt_banshee_cluster_id;
uint64_t const _snrt_banshee_global_offset = (uint64_t)0x10000000;

const uint32_t snrt_stack_size __attribute__((weak, section(".rodata"))) = 10;

void _snrt_init_team(uint32_t cluster_core_id, uint32_t cluster_core_num,
                     void *spm_start, void *spm_end, void *device_tree,
                     struct snrt_team_root *team) {
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
    team->global_mem.start = _snrt_banshee_global_start + _snrt_banshee_global_offset;
    team->global_mem.end = _snrt_banshee_global_end;
    team->cluster_mem.start = spm_start;
    team->cluster_mem.end = spm_end;

    // Allocate and initialize global barrier
    team->global_barrier = (void*)team->global_mem.start;
    team->global_barrier->barrier = 0;
    team->global_barrier->barrier_iteration = 0;
    team->global_mem.start += sizeof(struct snrt_barrier);

    // Allocate memory for a global mailbox.
    team->global_mailbox = team->global_mem.start;
    team->global_mem.start += sizeof(struct snrt_mailbox);

    // Allocate memory for a cluster mailbox.
    team->cluster_mem.end -= sizeof(struct snrt_mailbox);
    team->cluster_mailbox = team->cluster_mem.end;

    _snrt_team_current = &team->base;

    // Init allocator
    snrt_alloc_init(team);
}

// Provide an implementation for putchar.
void snrt_putchar(char character) {
    *(volatile uint32_t *)0xF00B8000 = character;
}
