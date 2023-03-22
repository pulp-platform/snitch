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

/**
 * Baseline kernels for a single core execution
 */

#define NUM_CLASSES 10
#define IN_CH 784
#define BATCH_SIZE 256

/**
 * SoftMax calculation
 */

static inline void SoftMax_baseline(float *activations, int length) {
    // printf("============= SoftMax feedforward start =============\n");
    float sum = 0;
    float max = activations[0];
    int correct, predict = 0;

    // Get the maximum value of all activations
    for (int i = 1; i < length; i++) {
        if (activations[i] > max) {
            max = activations[i];
        }
    }

    // normalize
    for (int i = 0; i < length; i++) {
        activations[i] = exp(activations[i] - max);
        sum += activations[i];
    }

    // compute softmax activations
    for (int i = 0; i < length; i++) {
        activations[i] /= sum;
        // printf("activations[%d] = %f\n", i, activations[i]);
    }

    // printf("============= SoftMax feedforward end =============\n");

    // snrt_cluster_hw_barrier();
}

/**
 * FeedForward calculation
 */

static inline void FeedForward_baseline(float *image, float *activations,
                                        float *biases, float *weights) {
    // printf("============= Feedforward pass start =============\n");

    // float checksum = 0;
    // float img_checksum = 0;
    // float weight_checksum = 0;
    for (int i = 0; i < NUM_CLASSES; i++) {
        activations[i] = biases[i];
        for (int j = 0; j < IN_CH; j++) {
            // img_checksum += image[j];
            // weight_checksum += weights[i * IN_CH + j];
            activations[i] += weights[i * IN_CH + j] * image[j];
        }

        // checksum += activations[i];

        // printf("activations[%d] = %f\n", i, activations[i]);
    }

    // printf("Activation checksum = %f\n", checksum);
    // printf("Image FeedForward checksum = %f\n", img_checksum);
    // printf("Weight FeedForward checksum = %f\n", weight_checksum);

    // printf("============= Feedforward pass end =============\n");

    // snrt_cluster_hw_barrier();

    SoftMax_baseline(activations, NUM_CLASSES);
}

/**
 * Gradient update calculation
 */

static inline void GradientUpdate_baseline(float *image, float *activations,
                                           float *biases, float *weights,
                                           float *W_gradients,
                                           float *b_gradients, uint32_t label,
                                           float *loss) {
    FeedForward_baseline(image, activations, biases, weights);

    loss[0] = 0.0f - log(activations[label]);
    // printf("loss = %f, label = %u, activation = %f\n", loss[0], label,
    // activations[label]);

    snrt_cluster_hw_barrier();

    float b_grad, W_grad;
    for (int i = 0; i < NUM_CLASSES; i++) {
        b_grad = (i == label) ? (activations[i] - 1) : activations[i];
        for (int j = 0; j < IN_CH; j++) {
            W_grad = b_grad * image[j];
            W_gradients[i * IN_CH + j] += W_grad;
        }

        b_gradients[i] += b_grad;
    }

    // return loss;
    snrt_cluster_hw_barrier();
}

/**
 * Training step calculation
 */

static inline void TrainingStep_baseline(float *biases, float *weights,
                                         float *W_gradients, float *b_gradients,
                                         float learning_rate) {
    // float b_checksum = 0;
    // float W_checksum = 0;
    // float b_grad_checksum = 0;
    // float W_grad_checksum = 0;
    for (int i = 0; i < NUM_CLASSES; i++) {
        biases[i] -= learning_rate * b_gradients[i] / BATCH_SIZE;
        // b_grad_checksum += b_gradients[i];
        // b_checksum += biases[i];
        for (int j = 0; j < IN_CH; j++) {
            weights[i * IN_CH + j] -=
                learning_rate * W_gradients[i * IN_CH + j] / BATCH_SIZE;
            // W_checksum += weights[i * IN_CH + j];
            // W_grad_checksum += W_gradients[i * IN_CH + j];
        }
    }

    // printf("b_checksum = %f\n", b_checksum);
    // printf("W_checksum = %f\n", W_checksum);
    // printf("b_grad_checksum = %f\n", b_grad_checksum);
    // printf("W_grad_checksum = %f\n", W_grad_checksum);

    snrt_cluster_hw_barrier();
}