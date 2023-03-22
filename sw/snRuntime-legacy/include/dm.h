// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <stdint.h>
#include <stdlib.h>

/**
 * @brief Init the data mover and load a pointer to the DM struct in to TLS.
 * Needs to be called by the DM itself and all harts that want to use the dm
 * functions
 *
 */
void dm_init(void);

/**
 * @brief data mover main function
 * @details
 */
void dm_main(void);

/**
 * @brief Send the data mover to exit()
 * @details
 */
void dm_exit(void);

/**
 * @brief Queue an asynchronus memory copy. The transfer is not started unless
 * dm_start or dm_wait is issued
 * @details block only if DM queue is full
 *
 * @param dest destination pointer
 * @param src source pointer
 * @param n number of bytes to copy
 * @return transfer ID
 */
void dm_memcpy_async(void *dest, const void *src, size_t n);

/**
 * @brief Queue an asynchronus memory copy. The transfer is not started unless
 * dm_start or dm_wait is issued
 * @details block only if DM queue is full
 *
 * @param src source address
 * @param dst destination address
 * @param size size in inner dimension
 * @param sstrd outer source stride
 * @param dstrd outer destination stride
 * @param nreps number of repetitions in outer dimension
 * @param cfg DMA configuration
 */
void dm_memcpy2d_async(uint64_t src, uint64_t dst, uint32_t size,
                       uint32_t sstrd, uint32_t dstrd, uint32_t nreps,
                       uint32_t cfg);

/**
 * @brief Trigger the start of queued transfers and exit immediately
 *
 */
void dm_start(void);

/**
 * @brief Wait for all DMA transfers to complete
 * @details
 */
void dm_wait(void);

/**
 * @brief Wait for the DM core to be ready
 * @details
 */
void dm_wait_ready(void);
