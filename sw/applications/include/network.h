// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>
#include "layer.h"

/**
 * @struct network_t_
 * @brief This structure contains all parameters necessary for building a simple neural netowork.
 * @var network_t_::IN_CH1
 * First dimension of the input data matrix (first channel)
 * @var network_t_::IN_CH2
 * Second dimension of the input data matrix (second channel)
 * @var network_t_::OUT_CH
 * Dimension of input matix along which we perform SoftMax
 * @var network_t_::b
 * Pointer to biases of the network
 * @var network_t_::W
 * Pointer to weights of the network
 * @var network_t_::b_grad
 * Pointer to bias gradients of the network
 * @var network_t_::W_grad
 * Pointer to weight gradients of the network
 * @var network_t_::dtype
 * Precision of the neural network (uniform for now)
 */

typedef struct network_t_ {
    uint32_t IN_CH1;
    uint32_t IN_CH2;
    uint32_t OUT_CH;

    float *b;
    float *W;
    float *b_grad;
    float *W_grad;
    float *images;
    uint32_t *targets;

    precision_t dtype;
    
} network_t;

typedef struct network_fp64_t_ {
    uint32_t IN_CH1;
    uint32_t IN_CH2;
    uint32_t OUT_CH;

    double *b;
    double *W;
    double *b_grad;
    double *W_grad;

    double *images;
    uint32_t *targets;
    float learning_rate;

    precision_t dtype;
    
} network_fp64_t;

typedef struct network_fp32_t_ {
    uint32_t IN_CH1;
    uint32_t IN_CH2;
    uint32_t OUT_CH;

    float *b;
    float *W;
    float *b_grad;
    float *W_grad;

    float *images;
    uint32_t *targets;
    float learning_rate;

    precision_t dtype;
    
} network_fp32_t;

typedef struct network_fp16_t_ {
    uint32_t IN_CH1;
    uint32_t IN_CH2;
    uint32_t OUT_CH;

    __fp16 *b;
    __fp16 *W;
    __fp16 *b_grad;
    __fp16 *W_grad;

    __fp16 *images;
    uint32_t *targets;
    float learning_rate;

    precision_t dtype;
    
} network_fp16_t;

typedef struct network_fp8_t_ {
    uint32_t IN_CH1;
    uint32_t IN_CH2;
    uint32_t OUT_CH;

    char *b;
    char *W;
    char *b_grad;
    char *W_grad;

    char *images;
    uint32_t *targets;
    float learning_rate;

    precision_t dtype;
    
} network_fp8_t;

// TODO: add description for MNIST CNN network struct
typedef struct cnn_t_ {
    uint16_t CO;
    uint16_t CI;
    uint16_t H;
    uint16_t W;
    uint16_t K;
    uint16_t M;
    
    uint16_t padding;
    uint16_t stride;

    double *image;
    double *conv1_weights;
    double *conv1_biases;

    precision_t dtype;
    
} cnn_t;

typedef struct network_benchmark_t_ {
    uint32_t IN_CH;
    uint32_t OUT_CH;

    void *b;
    void *W;

    void *images;
    uint32_t *targets;

    precision_t dtype;
    
} network_benchmark_t;

typedef struct network_single_cluster_t_ {
    uint32_t IN_CH;
    uint32_t OUT_CH;

    void *b;
    void *W;

    void *b_grads;
    void *W_grads;

    void *images;
    uint32_t *targets;

    precision_t dtype;
    
} network_single_cluster_t;
