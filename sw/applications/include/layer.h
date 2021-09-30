// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

typedef enum{
    CONV2D, GEMM, POOLING, BATCH_NORM
} LAYER_TYPE;

typedef enum {
    RELU, SOFTMAX
} ACTIVATION;

typedef enum {
    FP64=8, FP32=4, FP16=2, FP8=1
} PRECISION;

struct layer;
typedef struct layer_struct layer;

struct layer_struct
{
    LAYER_TYPE type;
    ACTIVATION activation;

    // GEMM
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

    uint32_t A_offset;
    uint32_t B_offset;
    uint32_t C_offset;

    uint32_t ldA;
    uint32_t ldB;
    uint32_t ldC;

    uint32_t ALPHA;

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

    PRECISION dtype;

};
