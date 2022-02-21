// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "snrt.h"

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
 *
 * @param pInBuffer pointer to the input feature map
 * @param dim_in_x width of input feature map
 * @param dim_in_y height of input feature map
 * @param ch_in number of input channels
 * @param pWeight pointer to weights
 * @param ch_out number of output channels
 * @param dim_kernel_x width of kernel
 * @param dim_kernel_y height of kernel
 * @param padding_y_top number of pixels padded on the top
 * @param padding_y_bottom number of pixels padded on the bottom
 * @param padding_x_left number of pixels padded on the left
 * @param padding_x_right number of pixels padded on the right
 * @param stride_x stride in x direction
 * @param stride_y stride in y direction
 * @param bias bias of convolution (currently not used)
 * @param bias_shift bias shift of convolution (currently not used)
 * @param out_shift shift factor for requantization (not used for floating
 * point)
 * @param out_mult mult factor for requantization (not used for floating point)
 * @param pOutBuffer pointer to output feature map
 * @param dim_out_x width of output feature map
 * @param dim_out_y height of output feature map
 * @param kappa multiplication factor for BatchNorm
 * @param lambda bias for BatchNorm
 * @param flag_relu RELU activation flag
 * @param flag_batch_norm BatchNorm flag
 * @param flag_y_accumulate_start indicates that output feature map is
 * initizialized with zeros
 * @param flag_y_accumulate_end indicates that BN, RELU can be performed
 * @param memory_chan Not used
 */
void __attribute__((noinline)) occamy_conv_opt_fp64(kernel_fp64 *k);

/**
 * @brief implementation of a single-precision fp convolutional kernel
 * for DORY trials. Currently does a direct convolution without im2col.
 * The memory layout of input/output feature map is HxWxC, resp. CoxFhxFwxCi.
 * Fuses multiple layers together (Conv2d, Batchnorm, Relu) that can be enabled
 * with a flag
 *
 * @param pInBuffer pointer to the input feature map
 * @param dim_in_x width of input feature map
 * @param dim_in_y height of input feature map
 * @param ch_in number of input channels (SIMD restricts multiple of 2)
 * @param pWeight pointer to weights
 * @param ch_out number of output channels
 * @param dim_kernel_x width of kernel
 * @param dim_kernel_y height of kernel
 * @param padding_y_top number of pixels padded on the top
 * @param padding_y_bottom number of pixels padded on the bottom
 * @param padding_x_left number of pixels padded on the left
 * @param padding_x_right number of pixels padded on the right
 * @param stride_x stride in x direction
 * @param stride_y stride in y direction
 * @param bias bias of convolution (currently not used)
 * @param bias_shift bias shift of convolution (currently not used)
 * @param out_shift shift factor for requantization (not used for floating
 * point)
 * @param out_mult mult factor for requantization (not used for floating point)
 * @param pOutBuffer pointer to output feature map
 * @param dim_out_x width of output feature map
 * @param dim_out_y height of output feature map
 * @param kappa multiplication factor for BatchNorm
 * @param lambda bias for BatchNorm
 * @param flag_relu RELU activation flag
 * @param flag_batch_norm BatchNorm flag
 * @param flag_y_accumulate_start indicates that output feature map is
 * initizialized with zeros
 * @param flag_y_accumulate_end indicates that BN, RELU can be performed
 * @param memory_chan Not used
 */

void __attribute__((noinline)) occamy_conv_opt_fp32(kernel_fp32 *k);

/**
 * @brief implementation of a single-precision fp DEPTHWISE convolutional kernel
 * for DORY trials. Currently does a direct convolution without im2col.
 * The memory layout of input/output feature map is HxWxC, resp. CoxFhxFwxCi.
 * Fuses multiple layers together (Conv2d, Batchnorm, Relu) that can be enabled
 * with a flag
 *
 * @param pInBuffer pointer to the input feature map
 * @param dim_in_x width of input feature map
 * @param dim_in_y height of input feature map
 * @param ch_in number of input channels (SIMD restricts multiple of 2)
 * @param pWeight pointer to weights
 * @param ch_out number of output channels (must be equal ch_in)
 * @param dim_kernel_x width of kernel
 * @param dim_kernel_y height of kernel
 * @param padding_y_top number of pixels padded on the top
 * @param padding_y_bottom number of pixels padded on the bottom
 * @param padding_x_left number of pixels padded on the left
 * @param padding_x_right number of pixels padded on the right
 * @param stride_x stride in x direction
 * @param stride_y stride in y direction
 * @param bias bias of convolution (currently not used)
 * @param bias_shift bias shift of convolution (currently not used)
 * @param out_shift shift factor for requantization (not used for floating
 * point)
 * @param out_mult mult factor for requantization (not used for floating point)
 * @param pOutBuffer pointer to output feature map
 * @param dim_out_x width of output feature map
 * @param dim_out_y height of output feature map
 * @param kappa multiplication factor for BatchNorm
 * @param lambda bias for BatchNorm
 * @param flag_relu RELU activation flag
 * @param flag_batch_norm BatchNorm flag
 * @param flag_y_accumulate_start indicates that output feature map is
 * initizialized with zeros
 * @param flag_y_accumulate_end indicates that BN, RELU can be performed
 * @param memory_chan Not used
 */
void __attribute__((noinline)) occamy_conv_dw_opt_fp32(kernel_fp32 *k);

/**
 * @brief implementation of a single-precision fp convolutional kernel
 * for DORY trials. Currently does a direct convolution without im2col.
 * The memory layout of input feature map is C x H x W, resp. Co x Fh x Fw x Ci
 * for weights Howevever, the output memory layout is H x W x C. This kernel
 * should be used for the first layers in a network where Ci is very small and
 * usually odd numbered. Fuses multiple layers together (Conv2d, Batchnorm,
 * Relu) that can be enabled with a flag
 *
 * @param pInBuffer pointer to the input feature map
 * @param dim_in_x width of input feature map
 * @param dim_in_y height of input feature map
 * @param ch_in number of input channels
 * @param pWeight pointer to weights
 * @param ch_out number of output channels
 * @param dim_kernel_x width of kernel (restricted to even numbers -> zero pad)
 * @param dim_kernel_y height of kernel
 * @param padding_y_top number of pixels padded on the top
 * @param padding_y_bottom number of pixels padded on the bottom
 * @param padding_x_left number of pixels padded on the left
 * @param padding_x_right number of pixels padded on the right
 * @param stride_x stride in x direction
 * @param stride_y stride in y direction
 * @param bias bias of convolution (currently not used)
 * @param bias_shift bias shift of convolution (currently not used)
 * @param out_shift shift factor for requantization (not used for floating
 * point)
 * @param out_mult mult factor for requantization (not used for floating point)
 * @param pOutBuffer pointer to output feature map
 * @param dim_out_x width of output feature map
 * @param dim_out_y height of output feature map
 * @param kappa multiplication factor for BatchNorm
 * @param lambda bias for BatchNorm
 * @param flag_relu RELU activation flag
 * @param flag_batch_norm BatchNorm flag
 * @param flag_y_accumulate_start indicates that output feature map is
 * initizialized with zeros
 * @param flag_y_accumulate_end indicates that BN, RELU can be performed
 * @param memory_chan Not used
 */
void __attribute__((noinline)) occamy_conv_chw_opt_fp32(kernel_fp32 *k);

/**
 * @brief helper function that implements Batch Normalization and ReLU
 *
 * @param pBuffer pointer to the feature map
 * @param dim_x width of feature map
 * @param dim_y height of feature map
 * @param ch number of channels (SIMD restricts multiple of 2)
 * @param kappa multiplication factor for BatchNorm
 * @param lambda bias for BatchNorm
 * @param flag_relu RELU activation flag
 * @param flag_batch_norm BatchNorm flag
 */
void __attribute__((noinline))
bn_relu(const float *pBuffer, const uint16_t dim_x, const uint16_t dim_y,
        const uint16_t ch, float *kappa, float *lambda, int flag_relu,
        int flag_batch_norm);
