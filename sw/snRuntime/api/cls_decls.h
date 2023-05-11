// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

typedef struct {
    uint32_t hw_barrier;
    snrt_allocator_t l1_allocator;
} cls_t;

inline cls_t* cls();
