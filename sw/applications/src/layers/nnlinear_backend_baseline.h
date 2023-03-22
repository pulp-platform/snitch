// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "network.h"

/**
 * @brief MNIST baseline network handling data transfers & function calls
 *        for a single core execution and no fancy optimizations like
 *        SSRs or FREP.
 *
 * @param n network_t struct holding all addresses and parameters
 *          which are in FP32 format
 */

void nnlinear_backend_baseline(const network_fp32_t *n);