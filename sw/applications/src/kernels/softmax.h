// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "math.h"
#include "printf.h"
#include "snrt.h"
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
 * Implementation of the SoftMax layer.
 */

static inline void softmax_fp32(float *input, float *output, int32_t ldI, int32_t batch_offset, 
                            int32_t batch_size, int32_t seq_len, int32_t input_samples) {

    float max_core = 0.0; // max value of the current core
    float sum = 0.0; // sum of the exp values of the current core

    uint32_t compute_id = snrt_cluster_compute_core_idx();
    uint32_t num_cores = snrt_cluster_compute_core_num();

    for (int32_t b = 0; b < batch_size; b++) {
        for (int32_t s = 0; s < seq_len; s++) {
            max_core = -INFINITY;
            sum = 0.0;

            for (int32_t i = 0; i < input_samples; i++) {
                if (input[b * batch_offset + s * ldI + i] > max_core) {
                    max_core = input[b * batch_offset + s * ldI + i];
                }
            }

            // compute the shifted value of the current row
            for (int32_t i = 0; i < input_samples; i++) {
                output[b * batch_offset + s * ldI + i] = expf(input[b * batch_offset + s * ldI + i] - max_core);
                sum += output[b * batch_offset + s * ldI + i];
            }

            // compute the softmax value of the current row
            for (int32_t i = 0; i < input_samples; i++) {
                output[b * batch_offset + s * ldI + i] /= sum;
            }

        }
    }

    snrt_cluster_hw_barrier();

}