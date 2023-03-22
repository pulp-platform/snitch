// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <snrt.h>

#include "printf.h"

int main() {
    int errors = 0;

    uint32_t n_inputs = 4;

    // Get memory locations
    uint32_t *zero_mem = (void *)(snrt_zero_memory().start);
    uint32_t *buffer_tcdm = (void *)snrt_cluster_memory().start;
    uint32_t *buffer_golden = (void *)(snrt_cluster_memory().start + 128);

    // printf("Zero Memory at %p\n", zero_mem);
    // printf("TCDM Memory at %p\n", buffer_tcdm);

    ///////////////
    // CORE READ //
    ///////////////
    if (snrt_cluster_compute_core_idx() == 0) {
        // Populate buffers.
        for (uint32_t i = 0; i < n_inputs; i++) {
            *(buffer_tcdm + i) = 1 + i;
            *(buffer_golden + i) = 1 + i;
        }
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core()) {
        // Copy data from ZeroMemory to TCDM memory.
        for (uint32_t i = 0; i < n_inputs; i++) {
            *(buffer_tcdm + i) = *(zero_mem + i);
        }
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_cluster_compute_core_idx() == 0) {
        // Check that the main memory buffer contains the correct data.
        for (uint32_t i = 0; i < n_inputs; i++) {
            errors += (int)((uint32_t) * (buffer_tcdm + i) != (uint32_t)0);
        }
        // printf("errors Copy: %i\n", errors);
    }
    // Barrier
    snrt_cluster_hw_barrier();

    //////////////////
    // DMA 1D WRITE //
    //////////////////
    if (snrt_cluster_compute_core_idx() == 0) {
        // Populate buffers.
        for (uint32_t i = 0; i < n_inputs; i++) {
            *(buffer_tcdm + i) = 1 + i;
            *(buffer_golden + i) = 1 + i;
        }
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core()) {
        // Copy data from TCDM memory to ZeroMemory.
        snrt_dma_start_1d(zero_mem, buffer_tcdm, n_inputs * sizeof(uint32_t));
        snrt_dma_wait_all();
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_cluster_compute_core_idx() == 0) {
        // Check that the main memory buffer contains the correct data.
        for (uint32_t i = 0; i < n_inputs; i++) {
            errors += (int)((uint32_t) * (buffer_tcdm + i) !=
                            (uint32_t) * (buffer_golden + i));
        }
        // printf("errors DMA 1D Write: %i\n", errors);
    }
    // Barrier
    snrt_cluster_hw_barrier();

    /////////////////
    // DMA 1D READ //
    /////////////////
    if (snrt_cluster_compute_core_idx() == 0) {
        // Populate buffers.
        for (uint32_t i = 0; i < n_inputs; i++) {
            *(buffer_tcdm + i) = 1 + i;
            *(buffer_golden + i) = 1 + i;
        }
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core()) {
        // Copy data from ZeroMemory to TCDM memory.
        snrt_dma_start_1d(buffer_tcdm, zero_mem, n_inputs * sizeof(uint32_t));
        snrt_dma_wait_all();
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_cluster_compute_core_idx() == 0) {
        // Check that the main memory buffer contains the correct data.
        for (uint32_t i = 0; i < n_inputs; i++) {
            errors += (int)((uint32_t) * (buffer_tcdm + i) != (uint32_t)0);
        }
        // printf("errors DMA 1D Read: %i\n", errors);
    }
    // Barrier
    snrt_cluster_hw_barrier();

    //////////////////
    // DMA 2D WRITE //
    //////////////////
    n_inputs = 1;

    if (snrt_cluster_compute_core_idx() == 0) {
        // Populate buffers.
        for (uint32_t i = 0; i < 20 * n_inputs; i++) {
            *(buffer_tcdm + i) = 1 + i;
            *(buffer_golden + i) = 1 + i;
        }
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core()) {
        // Copy data from TCDM memory to ZeroMemory.
        snrt_dma_start_2d(zero_mem, buffer_tcdm, n_inputs * sizeof(uint32_t), 0,
                          (2 * n_inputs) * sizeof(uint32_t), 4);
        snrt_dma_wait_all();
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_cluster_compute_core_idx() == 0) {
        // Check that the main memory buffer contains the correct data.
        for (uint32_t i = 0; i < n_inputs; i++) {
            errors += (int)((uint32_t) * (buffer_tcdm + i) !=
                            (uint32_t) * (buffer_golden + i));
        }
        // printf("errors DMA 2D Write: %i\n", errors);
    }
    // Barrier
    snrt_cluster_hw_barrier();

    /////////////////
    // DMA 2D READ //
    /////////////////
    n_inputs = 1;

    if (snrt_cluster_compute_core_idx() == 0) {
        // Populate buffers.
        for (uint32_t i = 0; i < 20 * n_inputs; i++) {
            *(buffer_tcdm + i) = 1 + i;
            *(buffer_golden + i) = 1 + i;
        }
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core()) {
        // Copy data from ZeroMemory to TCDM memory.
        snrt_dma_start_2d(buffer_tcdm, zero_mem, n_inputs * sizeof(uint32_t),
                          (2 * n_inputs) * sizeof(uint32_t), 0, 4);
        snrt_dma_wait_all();
    }
    // Barrier
    snrt_cluster_hw_barrier();
    if (snrt_cluster_compute_core_idx() == 0) {
        // Check that the main memory buffer contains the correct data.
        for (uint32_t i = 0; i < 4 * 2 * n_inputs; i++) {
            if ((i % 2) == 0) {
                errors += (int)((uint32_t) * (buffer_tcdm + i) != (uint32_t)0);
            } else {
                errors += (int)((uint32_t) * (buffer_tcdm + i) !=
                                (uint32_t) * (buffer_golden + i));
            }
            // printf("[%i] buffer_tcdm: %i buffer_golden %i\n", i,
            // *(buffer_tcdm + i), *(buffer_golden + i));
        }
        // printf("errors DMA 2D Read: %i\n", errors);
    }
    // Barrier
    snrt_cluster_hw_barrier();
    return errors;
}
