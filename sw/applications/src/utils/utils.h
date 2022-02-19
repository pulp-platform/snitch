// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "layer.h"
#include "snrt.h"

/**
 * @brief returns cycle number and injects marker
 * to track performance
 *
 * @return uint32_t
 */
uint32_t benchmark_get_cycle();

/**
 * @brief start tracking of dma performance region. Does not have any
 * implications on the HW. Only injects a marker in the DMA traces that can be
 * analyzed
 *
 */
void snrt_dma_start_tracking();

/**
 * @brief stop tracking of dma performance region. Does not have any
 * implications on the HW. Only injects a marker in the DMA traces that can be
 * analyzed
 *
 */
void snrt_dma_stop_tracking();

/**
 * @brief checks correctness of feature map
 *
 * @param l layer struct (Conv2d, BatchNorm, Maxpool)
 * @param checksum checksum to compare against, reduced over input channels
 * @return uint32_t
 */
uint32_t check_layer(const conv_layer* l, double* checksum);

/**
 * @brief fast memset function performed by DMA
 *
 * @param ptr pointer to the start of the region
 * @param value value to set
 * @param len number of bytes, must be multiple of DMA bus-width
 */
void dma_memset(void* ptr, uint8_t value, uint32_t len);
