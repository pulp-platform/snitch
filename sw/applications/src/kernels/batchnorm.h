// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

/**
 * @brief implementation of a FP64 batchnorm as a linear combination
 * y = gamma * x + beta
 *
 * @param ifmap pointer to input feature map
 * @param gamma pointer to gamma
 * @param beta pointer to beta
 * @param ofmap pointer to output feature map
 * @param OW width of output feature map
 * @param CI number of input channels
 * @param compute_num number of compute units
 * @param setup_SSR setup SSR strides and bounds
 */
void batchnorm_fp64(double *ifmap, double *gamma, double *beta, double *ofmap,
                    uint32_t OW, uint32_t CI, uint32_t compute_num,
                    uint32_t setup_SSR);
