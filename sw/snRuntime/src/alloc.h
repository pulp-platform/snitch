// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#define ALIGN_UP(addr, size) (((addr) + (size)-1) & ~((size)-1))
#define ALIGN_DOWN(addr, size) ((addr) & ~((size)-1))

#define MIN_CHUNK_SIZE 8

extern snrt_allocator_t l3_allocator;

inline snrt_allocator_t *snrt_l1_allocator() {
    return (snrt_allocator_t *)&(cls()->l1_allocator);
}

inline snrt_allocator_t *snrt_l3_allocator() { return &l3_allocator; }

inline void *snrt_l1_next() { return (void *)snrt_l1_allocator()->next; }

inline void *snrt_l3_next() { return (void *)snrt_l3_allocator()->next; }

/**
 * @brief Allocate a chunk of memory in the L1 memory
 * @details This currently does not support free-ing of memory
 *
 * @param size number of bytes to allocate
 * @return pointer to the allocated memory
 */
inline void *snrt_l1alloc(size_t size) {
    snrt_allocator_t *alloc = snrt_l1_allocator();

    // TODO colluca: do we need this? What does it imply?
    //               one more instruction, TCDM consumption...
    size = ALIGN_UP(size, MIN_CHUNK_SIZE);

    // TODO colluca
    // if (alloc->next + size > alloc->base + alloc->size) {
    //     snrt_trace(
    //         SNRT_TRACE_ALLOC,
    //         "Not enough memory to allocate: base %#x size %#x next %#x\n",
    //         alloc->base, alloc->size, alloc->next);
    //     return 0;
    // }

    void *ret = (void *)alloc->next;
    alloc->next += size;
    return ret;
}

/**
 * @brief Override the L1 allocator next pointer
 */
inline void snrt_l1_update_next(void *next) {
    snrt_allocator_t *alloc = snrt_l1_allocator();
    alloc->next = (uint32_t)next;
}

/**
 * @brief Allocate a chunk of memory in the L3 memory
 * @details This currently does not support free-ing of memory
 *
 * @param size number of bytes to allocate
 * @return pointer to the allocated memory
 */
inline void *snrt_l3alloc(size_t size) {
    snrt_allocator_t *alloc = snrt_l3_allocator();

    // TODO: L3 alloc size check

    void *ret = (void *)alloc->next;
    alloc->next += size;
    return ret;
}

inline void snrt_alloc_init() {
    // Only one core per cluster has to initialize the L1 allocator
    if (snrt_is_dm_core()) {
        // Initialize L1 allocator
        // Note: at the moment the allocator assumes all of the TCDM is
        // available for allocation. However, the CLS, TLS and stack already
        // occupy a possibly significant portion.
        snrt_l1_allocator()->base =
            ALIGN_UP(snrt_l1_start_addr(), MIN_CHUNK_SIZE);
        snrt_l1_allocator()->size = snrt_l1_end_addr() - snrt_l1_start_addr();
        snrt_l1_allocator()->next = snrt_l1_allocator()->base;
        // Initialize L3 allocator
        extern uint32_t _edram;
        snrt_l3_allocator()->base = ALIGN_UP((uint32_t)&_edram, MIN_CHUNK_SIZE);
        snrt_l3_allocator()->size = 0;
        snrt_l3_allocator()->next = snrt_l3_allocator()->base;
    }
}

// TODO colluca: optimize by using DMA
inline void *snrt_memset(void *ptr, int value, size_t num) {
    for (uint32_t i = 0; i < num; ++i)
        *((uint8_t *)ptr + i) = (unsigned char)value;
    return ptr;
}
