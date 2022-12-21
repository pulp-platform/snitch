// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

// Generate data in 64B blocks in *local* memory using FPU
static inline void gen_data_fpu_64B(void* ptr, double seed,
                                    uint32_t num_blocks) {
    volatile double* ptr_double = (volatile double*)ptr;
    for (uint32_t n = 0; n < num_blocks; ++n) {
        *(ptr_double + 8 * n) = seed * 3.141;
        *(ptr_double + 8 * n + 1) = seed * 2.718;
        *(ptr_double + 8 * n + 2) = seed * 57.30;
        *(ptr_double + 8 * n + 3) = seed * 6.022;
        *(ptr_double + 8 * n + 4) = seed * 0.1661;
        *(ptr_double + 8 * n + 5) = seed * 0.01745;
        *(ptr_double + 8 * n + 6) = seed * 0.3183;
        *(ptr_double + 8 * n + 7) = seed * 0.3679;
        seed = -seed - n;
    }
}

// Copy data in 64B blocks from location A to location B using FPU
static inline volatile uint32_t memcpy_fpu_64B(void* dst, void* src,
                                               uint32_t num_blocks) {
    uint32_t num_errors = 8 * num_blocks;  // 8 8B double words in 64B block
    volatile double* dst_double = (volatile double*)dst;
    volatile double* src_double = (volatile double*)src;
    for (uint32_t n = 0; n < num_blocks; ++n) {
        *(dst_double + 8 * n) = *(src_double + 8 * n);
        *(dst_double + 8 * n + 1) = *(src_double + 8 * n + 1);
        *(dst_double + 8 * n + 2) = *(src_double + 8 * n + 2);
        *(dst_double + 8 * n + 3) = *(src_double + 8 * n + 3);
        *(dst_double + 8 * n + 4) = *(src_double + 8 * n + 4);
        *(dst_double + 8 * n + 5) = *(src_double + 8 * n + 5);
        *(dst_double + 8 * n + 6) = *(src_double + 8 * n + 6);
        *(dst_double + 8 * n + 7) = *(src_double + 8 * n + 7);
    }
    return num_errors;
}

// Check data in 64B blocks in *local* memory using FPU; returns number of
// errors
static inline volatile uint32_t check_data_fpu_64B(void* ptr, void* gold,
                                                   uint32_t num_blocks) {
    uint32_t num_errors = 8 * num_blocks;  // 8 8B double words in 64B block
    volatile double* ptr_double = (volatile double*)ptr;
    volatile double* gold_double = (volatile double*)gold;
    for (uint32_t n = 0; n < num_blocks; ++n) {
        if (*(ptr_double + 8 * n) == *(gold_double + 8 * n)) --num_errors;
        if (*(ptr_double + 8 * n + 1) == *(gold_double + 8 * n + 1))
            --num_errors;
        if (*(ptr_double + 8 * n + 2) == *(gold_double + 8 * n + 2))
            --num_errors;
        if (*(ptr_double + 8 * n + 3) == *(gold_double + 8 * n + 3))
            --num_errors;
        if (*(ptr_double + 8 * n + 4) == *(gold_double + 8 * n + 4))
            --num_errors;
        if (*(ptr_double + 8 * n + 5) == *(gold_double + 8 * n + 5))
            --num_errors;
        if (*(ptr_double + 8 * n + 6) == *(gold_double + 8 * n + 6))
            --num_errors;
        if (*(ptr_double + 8 * n + 7) == *(gold_double + 8 * n + 7))
            --num_errors;
    }
    return num_errors;
}
