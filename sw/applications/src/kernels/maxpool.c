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
                  uint32_t FW, uint32_t compute_num) {
    for (uint32_t ci = 0; ci < CI; ci += compute_num) {
        register volatile double max = ifmap[ci];
        for (uint32_t fh = 0; fh < FH; fh++) {
            for (uint32_t fw = 0; fw < FW; fw++) {
                if (ifmap[(fh * FW + fw) * CI + ci] > max) {
                    max = ifmap[(fh * FW + fw) * CI + ci];
                }
            }
        }
        ofmap[ci] = max;
    }
}
