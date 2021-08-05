// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "debug.h"
#include "snrt.h"
#include "team.h"

/**
 * @brief Allocate a chunk of memory in the L1 memory
 * @details This currently does not support free-ing of memory
 *
 * @param size number of bytes to allocate
 * @return pointer to the allocated memory
 */
void *snrt_l1alloc(size_t size) {
    struct snrt_allocator *alloc = &snrt_current_team()->allocator;

    if (alloc->next + size > alloc->base + alloc->size) {
        snrt_trace(
            SNRT_TRACE_ALLOC,
            "Not enough memory to allocate: base %#x size %#x next %#x\n",
            alloc->base, alloc->size, alloc->next);
        return 0;
    }

    void *ret = (void *)alloc->next;
    alloc->next += size;
    return ret;
}

/**
 * @brief Init the allocator
 * @details
 *
 * @param snrt_team_root pointer to the team structure
 */
void snrt_alloc_init(struct snrt_team_root *team) {
    team->allocator.base = (uint32_t)team->cluster_mem.start;
    team->allocator.size =
        (uint32_t)(team->cluster_mem.end - team->cluster_mem.start);
    team->allocator.next = team->allocator.base;
}
