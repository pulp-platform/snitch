// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

typedef enum { FP64 = 8, FP32 = 4, FP16 = 2, FP8 = 1 } precision_t;

/**
 * @struct gemm_layer_struct
 * @brief This structure contains all parameters necessary for GEMM.
 * @var gemm_layer_struct::M
 * Dimension of matrix product MxK * KxN
 * @var gemm_layer_struct::M_p
 * M divided by number of compute cores
 * @var gemm_layer_struct::N
 * Dimension of matrix product MxK * KxN
 * @var gemm_layer_struct::K
 * Dimension of matrix product MxK * KxN
 * @var gemm_layer_struct::TA
 * Transpose matrix A
 * @var gemm_layer_struct::TB
 * Transpose matrix B
 * @var gemm_layer_struct::TILE_M
 * Tile factor across M dimension
 * @var gemm_layer_struct::TILE_N
 * Tile factor across N dimension
 * @var gemm_layer_struct::TILE_K
 * Tile factor across K dimension
 * @var gemm_layer_struct::A
 * Pointer to matrix A
 * @var gemm_layer_struct::B
 * Pointer to matrix B
 * @var gemm_layer_struct::C
 * Pointer to matrix C
 * @var gemm_layer_struct::ALPHA
 * constant factor: A * B + ALPHA * C
 * @var gemm_layer_struct::dtype
 * Precision of GEMM
 * @var gemm_layer_struct::expand
 * Use expanding DOTP instructions
 */
typedef struct gemm_layer_struct {
    uint32_t M;
    uint32_t M_p;
    uint32_t N;
    uint32_t K;

    uint32_t TA;
    uint32_t TB;

    uint32_t TILE_M;
    uint32_t TILE_N;
    uint32_t TILE_K;

    double *A;
    double *B;
    double *C;

    uint32_t ALPHA;

    precision_t dtype;
    uint32_t expand;
} gemm_layer;

/**
 * @struct conv_layer_struct
 * @brief This structure contains all parameters necessary for Convolutional
 * layers
 * @var conv_layer_struct::CO
 * Number of output channels
 * @var conv_layer_struct::CI
 * Number of input channels
 * @var conv_layer_struct::IH
 * Height of input feature map
 * @var conv_layer_struct::IW
 * Width of input feature map
 * @var conv_layer_struct::OH
 * Height of output feature map
 * @var conv_layer_struct::OW
 * Width of output feature map
 * @var conv_layer_struct::FH
 * Height of filter
 * @var conv_layer_struct::FW
 * Width of filter
 * @var conv_layer_struct::pad
 * Padding on all sides
 * @var conv_layer_struct::ifmap
 * Pointer to input feature map
 * @var conv_layer_struct::weights
 * Pointer to weights
 * @var conv_layer_struct::ofmap
 * Pointer to output feature map
 * @var conv_layer_struct::TILE_CI
 * Tiling factor of input channel
 * @var conv_layer_struct::cluster2cluster
 * Flag for enabling cluster 2 cluster communication
 * @var conv_layer_struct::im2col
 * Flag for enabling im2col + GEMM
 * @var conv_layer_struct::gamma
 * Pointer to gamma for BatchNorm
 * @var conv_layer_struct::beta
 * Pointer to beta for BatchNorm
 * @var gemm_layer_struct::dtype
 * Precision of Convolution layer
 */
typedef struct conv_layer_struct {
    // CONV2D
    uint32_t CO;
    uint32_t CI;
    uint32_t IH;
    uint32_t IW;
    uint32_t OH;
    uint32_t OW;
    uint32_t FH;
    uint32_t FW;
    uint32_t pad;

    double *ifmap;
    double *weights;
    double *ofmap;

    uint32_t TILE_CI;
    uint32_t cluster2cluster;
    uint32_t im2col;

    // BATCHNORM
    double *gamma;
    double *beta;

    precision_t dtype;
} conv_layer;

/**
 * @struct linear_layer_struct
 * @brief This structure contains all parameters necessary for Linear layers
 * @var linear_layer_struct::CO
 * Size of each output sample
 * @var linear_layer_struct::CI
 * Size of each input sample
 * @var linear_layer_struct::CH
 * Height of input feature map
 * @var linear_layer_struct::CW
 * Width of input feature map
 * @var linear_layer_struct::ifmap
 * Pointer to input feature map
 * @var linear_layer_struct::weights
 * Pointer to weights
 * @var linear_layer_struct::bias
 * Pointer to bias
 * @var linear_layer_struct::ofmap
 * Pointer to output feature map
 */

typedef struct linear_layer_struct {
    uint32_t CO;
    uint32_t CI;
    uint32_t CH;
    uint32_t CW;

    float *ifmap;
    float *weights;
    float *bias;
    float *ofmap;
    float *result;

    precision_t dtype;
} linear_layer_t;

/**
 * @struct gelu_layer_struct
 * @brief This structure contains all parameters necessary
 *        for computing the GELU activation function
 * @var gelu_layer_struct::BATCH_SIZE
 * Size of each input sample
 * @var gelu_layer_struct::SEQ_LEN
 * Size of each output sample
 * @var gelu_layer_struct::HIDDEN_NODES
 * Number of hidden dimensions
 * @var gelu_layer_struct::ifmap
 * Pointer to input feature map
 * @var gelu_layer_struct::ofmap
 * Pointer to output feature map
 * @var gelu_layer_struct::result
 * Pointer to the golden model output
 */

typedef struct gelu_layer_struct {
    uint32_t BATCH_SIZE;
    uint32_t SEQ_LEN;
    uint32_t HIDDEN_NODES;

    float *ifmap;
    float *ofmap;
    float *result;

    precision_t dtype;
} gelu_layer_t;

/**
 * @struct softmax_layer_struct
 * @brief This structure contains all parameters necessary
 *       for computing the Softmax activation function
 * @var softmax_layer_struct::BATCH_SIZE
 * Size of each input sample
 * @var softmax_layer_struct::SEQ_LEN
 * Size of each output sample
 * @var softmax_layer_struct::INPUT_SAMPLES
 * Number of input samples
 * @var softmax_layer_struct::REDUCE_DIM
 * Along which dimension to reduce
 * @var softmax_layer_struct::ifmap
 * Pointer to input feature map
 * @var softmax_layer_struct::ofmap
 * Pointer to output feature map
 * @var softmax_layer_struct::result
 * Pointer to the golden model output
 */

typedef struct softmax_layer_struct {
    uint32_t BATCH_SIZE;
    uint32_t SEQ_LEN;
    uint32_t INPUT_SAMPLES;
    uint32_t REDUCE_DIM;

    float *ifmap;
    float *ofmap;
    float *result;

    precision_t dtype;
} softmax_layer_t;

/**
 * @struct layernorm_layer_struct
 * @brief This structure contains all parameters necessary
 *        for computing the LayerNorm activation function
 * @var layernorm_layer_struct::BATCH_SIZE
 * Size of each input sample
 * @var layernorm_layer_struct::SEQ_LEN
 * Size of each output sample
 * @var layernorm_layer_struct::EMBEDDINGS
 * Number of hidden dimensions
 * @var layernorm_layer_struct::ifmap
 * Pointer to input feature map
 * @var layernorm_layer_struct::ofmap
 * Pointer to output feature map
 * @var layernorm_layer_struct::result
 * Pointer to the golden model output
 */

typedef struct layernorm_layer_struct {
    uint32_t BATCH_SIZE;
    uint32_t SEQ_LEN;
    uint32_t EMBEDDINGS;
    uint32_t EPS;

    float *ifmap;
    float *ofmap;
    float *result;

    precision_t dtype;
} layernorm_layer_t;