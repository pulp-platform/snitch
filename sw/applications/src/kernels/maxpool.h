// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

/**
 * @brief implementation of FP64 maxpooling
 *
 * @param ifmap pointer to input feature map
 * @param ofmap pointer to output feature map
 * @param CI number of input channels
 * @param FH height of filter
 * @param FW width of filter
 * @param compute_num number of compute units
 */
void maxpool_fp64(double *ifmap, double *ofmap, uint32_t CI, uint32_t FH,
                  uint32_t FW, uint32_t compute_num);
