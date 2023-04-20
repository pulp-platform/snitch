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

#define M_PI 3.14159265358979323846

/**
 * Implementation of the GELU layer
 */

static inline void gelu_fp32(float *input, float *output, int32_t ldI, uint32_t batch_size,
                             uint32_t seq_len, uint32_t hidden_nodes) {

    // uint32_t compute_id = snrt_cluster_compute_core_idx();

    for (int s = 0; s < seq_len; s++) {
        for (int h = 0; h < hidden_nodes; h++) {
            // if (compute_id == 1) {
            //     printf("compute id: %d, input[%d][%d] = %f\n", compute_id, s, h,
            //         input[s * hidden_nodes + h]);
            // }
            float x = input[s * hidden_nodes + h];
            float y = 0.5 * x * (1.0 + tanh(sqrt(2.0 / M_PI) * (x + 0.044715 * x * x * x)));
            output[s * hidden_nodes + h] = y;

            // if (compute_id == 1) {
            //     printf("compute id: %d, output[%d][%d] = %f\n", compute_id, s, h,
            //         output[s * hidden_nodes + h]);
            // }

        }
    }

}