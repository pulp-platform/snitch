// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <snrt.h>

#include "occamy_quad_peripheral.h"

#define OCCAMY_QUADRANT_S1_OFFSET 0x0B000000

extern uint32_t _stext;
extern uint32_t _etext;

// Allocate a buffer in the main memory which we will use to copy data around
// with the DMA.
#define buffer_size 128
uint32_t buffer[buffer_size] __attribute__((aligned(512 / 4)));

int main() {

  if (snrt_global_core_idx() == 0) {
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_START_ADDR_LOW_0_REG_OFFSET) =
        (uint32_t) & _stext;
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_0_REG_OFFSET) =
        (uint32_t)0;
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_END_ADDR_LOW_0_REG_OFFSET) =
        (uint32_t) & _etext;
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_0_REG_OFFSET) =
        (uint32_t)0;

    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_START_ADDR_LOW_1_REG_OFFSET) =
        (uint32_t) & buffer;
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_START_ADDR_HIGH_1_REG_OFFSET) =
        (uint32_t)1;
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_END_ADDR_LOW_1_REG_OFFSET) =
        (uint32_t) & buffer[buffer_size];
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_END_ADDR_HIGH_1_REG_OFFSET) =
        (uint32_t)1;

    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_CACHE_ENABLE_REG_OFFSET) = 1;
  }

  snrt_global_barrier();

  uint32_t errors = 0;
  uint32_t buffer_src[buffer_size], buffer_dst[buffer_size];

  if ((snrt_global_core_idx() + 1) % 9 == 0) { // only DMA core

    // Populate buffers.
    for (uint32_t i = 0; i < buffer_size; i++) {
      buffer[i] = 0xAAAAAAAA;
      buffer_dst[i] = 0x55555555;
      buffer_src[i] = i + 1;
    }

    // Copy data to main memory.
    snrt_dma_start_1d(buffer, buffer_src, sizeof(buffer));
    snrt_dma_wait_all();

    // Check that the main memory buffer contains the correct data.
    for (uint32_t i = 0; i < buffer_size; i++) {
      errors += (buffer[i] != buffer_src[i]);
    }

    // Copy data to L1.
    snrt_dma_start_1d(buffer_dst, buffer, sizeof(buffer));
    snrt_dma_wait_all();

    // Check that the L1 buffer contains the correct data.
    for (uint32_t i = 0; i < buffer_size; i++) {
      errors += (buffer_dst[i] != buffer_src[i]);
    }
  }
  snrt_global_barrier();

  // Disable an flush the cache
  if (snrt_global_core_idx() == 0) {
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_CACHE_ENABLE_REG_OFFSET) = 0;
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_CACHE_FLUSH_REG_OFFSET) = 1;
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_CACHE_FLUSH_REG_OFFSET) = 0;
    *(volatile uint32_t *)(OCCAMY_QUADRANT_S1_OFFSET +
                           OCCAMY_QUADRANT_S1_RO_CACHE_ENABLE_REG_OFFSET) = 1;
  }

  snrt_global_barrier();

  if ((snrt_global_core_idx() + 1) % 9 == 0) { // only DMA core

    // Populate buffers.
    for (uint32_t i = 0; i < buffer_size; i++) {
      buffer[i] = 0xAAAAAAAA;
      buffer_dst[i] = 0x55555555;
      buffer_src[i] = i + 1;
    }

    // Copy data to L1.
    snrt_dma_start_1d(buffer_dst, buffer, sizeof(buffer));
    snrt_dma_wait_all();

    // Check that the L1 buffer contains the correct data.
    for (uint32_t i = 0; i < buffer_size; i++) {
      errors += (buffer_dst[i] != buffer_src[i]);
    }

  }
  snrt_global_barrier();

  return errors;
}
