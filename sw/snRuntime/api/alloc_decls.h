// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

typedef struct {
    // Base address from where allocation starts
    uint32_t base;
    // Number of bytes alloctable
    uint32_t size;
    // Address of the next allocated block
    uint32_t next;
} snrt_allocator_t;

inline void *snrt_l1_next();

inline void *snrt_l3_next();

inline void *snrt_l1alloc(size_t size);

inline void snrt_l1_update_next(void *next);

inline void *snrt_l3alloc(size_t size);

inline void snrt_alloc_init();
