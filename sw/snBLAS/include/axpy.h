// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <snblas.h>
#include <stdint.h>

/**
 * @brief Double-buffering AXPY. TCDM footprint ~= 32*tile_n*sizeof(double)
 * @details dy[i] = dy[i] + alpha*dx[i]
 *
 * @param n Problem size
 * @param tile_n Tiling size
 * @param alpha pointer to alpga
 * @param dx pointer to data x
 * @param dy pointer to data y
 * @param ccfg compute configuration struct
 */
void axpy_block(uint32_t n, uint32_t tile_n, double *alpha, double *dx, double *dy,
                computeConfig_t *ccfg);

/**
 * @brief DAXPY constant times a vector plus a vector.
 * @details dy[i] = dy[i] + alpha*dx[i]
 *
 * @param n number of elements to process
 * @param alpha scalar alpha
 * @param dx double array
 * @param dy double array
 * @param setup_ssr Set to non-zero if the problem size changed since the last call or the SSRs have
 * been used with a different configuration. Set to zero for faster execution
 */
void axpy(uint32_t n, double *alpha, double *dx, double *dy, uint32_t setup_ssr);

/**
 * @brief Test `axpy` and return number of mismatches
 *
 * @return Number of mismatches
 */
unsigned test_axpy(void);
