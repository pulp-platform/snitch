// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "math.h"
#include "snrt.h"
#include "printf.h"
#include "utils.h"

typedef float v2f32 __attribute__((vector_size(8)));
typedef __fp16 v4f16 __attribute__((vector_size(8)));
typedef char v8f8 __attribute__((vector_size(8)));

typedef union {
    double f64;
    v2f32 vec;
} v2s;
typedef union {
    double f64;
    v4f16 vec;
} v4s;
typedef union {
    double f64;
    v8f8 vec;
} v8s;

#define INFINITY 0x7f800000

/**
 * Implementation of the LayerNorm layer.
 */

static inline void layernorm_fp32(float *input, float *output, int32_t ldI,
                                  int32_t batch_offset, int32_t batch_size,
                                  int32_t seq_len, int32_t embeddings,
                                  int32_t eps) {
    float mean = 0.0;  // max value of the current core
    float var = 0.0;   // sum of the exp values of the current core

    uint32_t compute_id = snrt_global_core_idx();
    uint32_t num_cores = snrt_cluster_compute_core_num();

    // compute the mean and variance along the last dimension
    for (int32_t b = 0; b < batch_size; b++) {
        for (int32_t s = 0; s < seq_len; s++) {
            mean = 0.0;
            var = 0.0;

            for (int32_t i = 0; i < embeddings; i++) {
                mean += input[b * batch_offset + s * ldI + i];
            }
            mean /= embeddings;

            // printf("mean[%d] = %f\n", b, mean);

            for (int32_t i = 0; i < embeddings; i++) {
                var += (input[b * batch_offset + s * ldI + i] - mean) *
                       (input[b * batch_offset + s * ldI + i] - mean);
            }
            var /= embeddings;

            // printf("var[%d] = %f\n", b, var);

            // compute the shifted value of the current row
            for (int32_t i = 0; i < embeddings; i++) {
                output[b * batch_offset + s * ldI + i] =
                    (input[b * batch_offset + s * ldI + i] - mean) /
                    sqrtf(var + eps);
                // printf("output[%d][%d][%d] = %f\n", b, s + compute_id, i,
                //        output[b * batch_offset + s * ldI + i]);
            }
        }
    }

    snrt_cluster_hw_barrier();
}