// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <stdint.h>

/**
 * @brief Struct used to configure and profile kernels in snBLAS
 *
 */
typedef struct computeConfig
{
    uint32_t cluster_num;
    uint32_t compute_num;
    uint32_t cluster_idx;
    uint32_t cycle_start;
    uint32_t cycle_end;
    uint32_t *stmps;
    uint32_t max_stmps;
} computeConfig_t;

double snblas_hello();
