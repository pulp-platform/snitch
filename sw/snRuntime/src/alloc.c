// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "debug.h"
#include "snrt.h"
#include "team.h"

#define ALIGN_UP(addr, size) (((addr) + (size)-1) & ~((size)-1))
#define ALIGN_DOWN(addr, size) ((addr) & ~((size)-1))

#define MIN_CHUNK_SIZE 8

/**
 * @brief Allocate a chunk of memory in the L1 memory
 * @details This currently does not support free-ing of memory
 *
 * @param size number of bytes to allocate
 * @return pointer to the allocated memory
 */
void *snrt_l1alloc(size_t size) {
    struct snrt_allocator_inst *alloc = &snrt_current_team()->allocator.l1;

    size = ALIGN_UP(size, MIN_CHUNK_SIZE);

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
 * @brief Allocate a chunk of memory in the L3 memory
 * @details This currently does not support free-ing of memory
 *
 * @param size number of bytes to allocate
 * @return pointer to the allocated memory
 */
void *snrt_l3alloc(size_t size) {
    struct snrt_allocator_inst *alloc = &snrt_current_team()->allocator.l3;

    // TODO: L3 alloc size check

    void *ret = (void *)alloc->next;
    alloc->next += size;
    return ret;
}

/**
 * @brief Init the allocator
 * @details
 *
 * @param snrt_team_root pointer to the team structure
 * @param l3off Number of bytes to skip on _edram before starting allocator
 */
void snrt_alloc_init(struct snrt_team_root *team, uint32_t l3off) {
    // Allocator in L1 TCDM memory
    team->allocator.l1.base =
        ALIGN_UP((uint32_t)team->cluster_mem.start, MIN_CHUNK_SIZE);
    team->allocator.l1.size =
        (uint32_t)(team->cluster_mem.end - team->cluster_mem.start);
    team->allocator.l1.next = team->allocator.l1.base;
    // Allocator in L3 shared memory
    extern uint32_t _edram;
    team->allocator.l3.base =
        ALIGN_UP((uint32_t)_edram + l3off, MIN_CHUNK_SIZE);
    ;
    team->allocator.l3.size = 0;
    team->allocator.l3.next = team->allocator.l3.base;
}
