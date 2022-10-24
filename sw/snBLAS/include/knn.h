// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <snblas.h>
#include <stdint.h>

struct knn_aux {
  double dist;
  uint32_t index;
};

/**
 * @brief kNN algorithm. For each sample in `query`, calculate the euclidean distance to all data
 * points in `data` and sort. Output is stored in `output`. `k` is currently ignored.
 *
 * @param K k in k-nn
 * @param query_size number os samples to query
 * @param data_size size of data set
 * @param query elements to classify
 * @param data input data set
 * @param output sorted list with classifications
 * @param ccfg compute configuration struct
 */
void knn_1d(uint32_t K, uint32_t query_size, uint32_t data_size, double *query, double *data,
            struct knn_aux *output, computeConfig_t *ccfg);
