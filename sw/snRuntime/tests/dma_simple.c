// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <snrt.h>

// Allocate a buffer in the main memory which we will use to copy data around
// with the DMA.
uint32_t buffer[32];

int main() {
    if (snrt_global_core_idx() != 8) return 0;  // only DMA core
    uint32_t errors = 0;

    // Populate buffers.
    uint32_t buffer_src[32], buffer_dst[32];
    for (uint32_t i = 0; i < 32; i++) {
        buffer[i] = 0xAAAAAAAA;
        buffer_dst[i] = 0x55555555;
        buffer_src[i] = i + 1;
    }

    // Copy data to main memory.
    snrt_dma_start_1d(buffer, buffer_src, sizeof(buffer));
    snrt_dma_wait_all();

    // Check that the main memory buffer contains the correct data.
    for (uint32_t i = 0; i < 32; i++) {
        errors += (buffer[i] != buffer_src[i]);
    }

    // Copy data to L1.
    snrt_dma_start_1d(buffer_dst, buffer, sizeof(buffer));
    snrt_dma_wait_all();

    // Check that the L1 buffer contains the correct data.
    for (uint32_t i = 0; i < 32; i++) {
        errors += (buffer_dst[i] != buffer_src[i]);
    }

    return errors;
}
