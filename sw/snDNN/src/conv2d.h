// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "snrt.h"

/**
 * @struct kernel_fp32
 * @brief parameters for single-precision fusedconv kernel
 *
 * @var kernel_fp32::pInBuffer
 * pointer to the input feature map
 * @var kernel_fp32::dim_in_x
 * width of input feature map
 * @var kernel_fp32::dim_in_y
 * height of input feature map
 * @var kernel_fp32::ch_in
 * number of input channels
 * @var kernel_fp32::pWeight
 * pointer to weights
 * @var kernel_fp32::ch_out
 * number of output channels
 * @var kernel_fp32::dim_kernel_x
 * width of kernel
 * @var kernel_fp32::dim_kernel_y
 * height of kernel
 * @var kernel_fp32::padding_y_top
 * number of pixels padded on the top
 * @var kernel_fp32::padding_y_bottom
 * number of pixels padded on the bottom
 * @var kernel_fp32::padding_x_left
 * number of pixels padded on the left
 * @var kernel_fp32::padding_x_right
 * number of pixels padded on the right
 * @var kernel_fp32::stride_x
 * stride in x direction
 * @var kernel_fp32::stride_y
 * stride in y direction
 * @var kernel_fp32::bias
 * bias of convolution (currently not used)
 * @var kernel_fp32::bias_shift
 * bias shift of convolution (currently not used)
 * @var kernel_fp32::out_shift
 * shift factor for requantization (not used for floating point)
 * @var kernel_fp32::out_mult
 * mult factor for requantization (not used for floating point)
 * @var kernel_fp32::pOutBuffer
 * pointer to output feature map
 * @var kernel_fp32::dim_out_x
 * width of output feature map
 * @var kernel_fp32::dim_out_y
 * height of output feature map
 * @var kernel_fp32::kappa
 * multiplication factor for BatchNorm
 * @var kernel_fp32::lambda
 * @var kernel_fp32::pIm2ColBuffer
 * pointer to im2col Buffer (not used)
 * bias for BatchNorm
 * @var kernel_fp32::flag_relu
 * RELU activation flag
 * @var kernel_fp32::flag_batch_norm
 * BatchNorm flag
 * @var kernel_fp32::flag_y_accumulate_start
 * indicates that output feature map is initizialized with zeros
 * @var kernel_fp32::flag_y_accumulate_end
 * indicates that BN, RELU can be performed
 * @var kernel_fp32::memory_chan
 * Not used
 */

typedef struct {
    float *pInBuffer;
    uint16_t dim_in_x;
    uint16_t dim_in_y;
    uint16_t ch_in;
    float *pWeight;
    uint16_t ch_out;
    uint16_t dim_kernel_x;
    uint16_t dim_kernel_y;
    uint16_t padding_y_top;
    uint16_t padding_y_bottom;
    uint16_t padding_x_left;
    uint16_t padding_x_right;
    uint16_t stride_x;
    uint16_t stride_y;
    int8_t *bias;
    uint16_t bias_shift;
    uint16_t out_shift;
    uint16_t out_mult;
    float *pOutBuffer;
    uint16_t dim_out_x;
    uint16_t dim_out_y;
    float *kappa;
    float *lambda;
    uint8_t *pIm2ColBuffer;
    int flag_relu;
    int flag_batch_norm;
    int flag_y_accumulate_start;
    int flag_y_accumulate_end;
    unsigned int *memory_chan;
} kernel_fp32;

/**
 * @struct kernel_fp64
 * @brief parameters for double-precision fusedconv kernel
 *
 * @var kernel_fp64::pInBuffer
 * pointer to the input feature map
 * @var kernel_fp64::dim_in_x
 * width of input feature map
 * @var kernel_fp64::dim_in_y
 * height of input feature map
 * @var kernel_fp64::ch_in
 * number of input channels
 * @var kernel_fp64::pWeight
 * pointer to weights
 * @var kernel_fp64::ch_out
 * number of output channels
 * @var kernel_fp64::dim_kernel_x
 * width of kernel
 * @var kernel_fp64::dim_kernel_y
 * height of kernel
 * @var kernel_fp64::padding_y_top
 * number of pixels padded on the top
 * @var kernel_fp64::padding_y_bottom
 * number of pixels padded on the bottom
 * @var kernel_fp64::padding_x_left
 * number of pixels padded on the left
 * @var kernel_fp64::padding_x_right
 * number of pixels padded on the right
 * @var kernel_fp64::stride_x
 * stride in x direction
 * @var kernel_fp64::stride_y
 * stride in y direction
 * @var kernel_fp64::bias
 * bias of convolution (currently not used)
 * @var kernel_fp64::bias_shift
 * bias shift of convolution (currently not used)
 * @var kernel_fp64::out_shift
 * shift factor for requantization (not used for floating point)
 * @var kernel_fp64::out_mult
 * mult factor for requantization (not used for floating point)
 * @var kernel_fp64::pOutBuffer
 * pointer to output feature map
 * @var kernel_fp64::dim_out_x
 * width of output feature map
 * @var kernel_fp64::dim_out_y
 * height of output feature map
 * @var kernel_fp64::kappa
 * multiplication factor for BatchNorm
 * @var kernel_fp64::lambda
 * bias for BatchNorm
 * @var kernel_fp64::pIm2ColBuffer
 * pointer to im2col Buffer (not used)
 * @var kernel_fp64::flag_relu
 * RELU activation flag
 * @var kernel_fp64::flag_batch_norm
 * BatchNorm flag
 * @var kernel_fp64::flag_y_accumulate_start
 * indicates that output feature map is initizialized with zeros
 * @var kernel_fp64::flag_y_accumulate_end
 * indicates that BN, RELU can be performed
 * @var kernel_fp64::memory_chan
 * Not used
 */
typedef struct {
    double *pInBuffer;
    uint16_t dim_in_x;
    uint16_t dim_in_y;
    uint16_t ch_in;
    double *pWeight;
    uint16_t ch_out;
    uint16_t dim_kernel_x;
    uint16_t dim_kernel_y;
    uint16_t padding_y_top;
    uint16_t padding_y_bottom;
    uint16_t padding_x_left;
    uint16_t padding_x_right;
    uint16_t stride_x;
    uint16_t stride_y;
    int8_t *bias;
    uint16_t bias_shift;
    uint16_t out_shift;
    uint16_t out_mult;
    double *pOutBuffer;
    uint16_t dim_out_x;
    uint16_t dim_out_y;
    double *kappa;
    double *lambda;
    uint8_t *pIm2ColBuffer;
    int flag_relu;
    int flag_batch_norm;
    int flag_y_accumulate_start;
    int flag_y_accumulate_end;
    unsigned int *memory_chan;
} kernel_fp64;

/**
 * @brief implementation of a double-precision fp convolutional kernel
 * for DORY trials. Currently does a direct convolution without im2col.
 * The memory layout of input/output feature map is HxWxC, resp. CoxFhxFwxCi.
 * Fuses multiple layers together (Conv2d, Batchnorm, Relu) that can be enabled
 * with a flag
 * @param k kernel_fp64 struct reference that holds all parameters
 */
void occamy_conv_opt_fp64(kernel_fp64 *k);

/**
 * @brief implementation of a single-precision fp convolutional kernel
 * for DORY trials. Currently does a direct convolution without im2col.
 * The memory layout of input/output feature map is HxWxC, resp. CoxFhxFwxCi.
 * Fuses multiple layers together (Conv2d, Batchnorm, Relu) that can be enabled
 * with a flag
 * @param k kernel_fp32 struct reference that holds all parameters
 */
void occamy_conv_opt_fp32(kernel_fp32 *k);

/**
 * @brief implementation of a single-precision fp DEPTHWISE convolutional kernel
 * for DORY trials. Currently does a direct convolution without im2col.
 * The memory layout of input/output feature map is HxWxC, resp. CoxFhxFwxCi.
 * Fuses multiple layers together (Conv2d, Batchnorm, Relu) that can be enabled
 * with a flag
 * @param k kernel_fp32 struct reference that holds all parameters
 */
void occamy_conv_dw_opt_fp32(kernel_fp32 *k);

/**
 * @brief implementation of a single-precision fp convolutional kernel
 * for DORY trials. Currently does a direct convolution without im2col.
 * The memory layout of input feature map is C x H x W, resp. Co x Fh x Fw x Ci
 * for weights Howevever, the output memory layout is H x W x C. This kernel
 * should be used for the first layers in a network where Ci is very small and
 * usually odd numbered. Fuses multiple layers together (Conv2d, Batchnorm,
 * Relu) that can be enabled with a flag
 * @param k kernel_fp32 struct reference that holds all parameters
 */
void occamy_conv_chw_opt_fp32(kernel_fp32 *k);

/**
 * @brief helper function that implements Batch Normalization and ReLU
 * @param pBuffer pointer to the feature map
 * @param dim_x width of feature map
 * @param dim_y height of feature map
 * @param ch number of channels (SIMD restricts multiple of 2)
 * @param kappa multiplication factor for BatchNorm
 * @param lambda bias for BatchNorm
 * @param flag_relu RELU activation flag
 * @param flag_batch_norm BatchNorm flag
 */
void bn_relu(const float *pBuffer, const uint16_t dim_x, const uint16_t dim_y,
             const uint16_t ch, float *kappa, float *lambda, int flag_relu,
             int flag_batch_norm);
