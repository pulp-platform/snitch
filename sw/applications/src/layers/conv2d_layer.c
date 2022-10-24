// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "layer.h"
#include "conv2d_layer.h"
#include "gemm.h"
#include "utils.h"
#include "printf.h"
#include "snrt.h"

#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))

void conv2d_layer(layer l) {

    uint32_t cluster_num = snrt_cluster_num();
    uint32_t cluster_id = snrt_cluster_idx();
    uint32_t compute_num = snrt_cluster_compute_core_num();
    uint32_t compute_id = snrt_cluster_compute_core_idx();

    const uint32_t cluster_per_quadrant = min(4, cluster_num);

    // typedef struct cluster_mem_alloc_struct {
    //     double im2col[2][compute_num][l.FW*l.FH*l.TILE_CI+1];
    //     double ifmap[2][l.FH][compute_num + l.FW - 1][l.TILE_CI];
    //     double weights[compute_num][l.FH*l.FW*l.TILE_CI+1];
    //     double ofmap[2][compute_num][8];
    //     volatile uint32_t synch_flag[2];
    // } cluster_mem_alloc;

    // im2col[2][compute_num][l.FW*l.FH*l.TILE_CI+1];
    uint32_t im2col_row_stride = l.FW*l.FH*l.TILE_CI+1;
    uint32_t im2col_mat_stride = im2col_row_stride * compute_num;
    uint32_t im2col_size = 2 * im2col_mat_stride;

    // ifmap[2][l.FH][compute_num + l.FW - 1][l.TILE_CI];
    uint32_t ifmap_col_stride = l.TILE_CI;
    uint32_t ifmap_row_stride = ifmap_col_stride * (compute_num + l.FW - 1);
    uint32_t ifmap_stride = ifmap_row_stride * l.FH;
    uint32_t ifmap_size = 2 * ifmap_stride;

    // weights[compute_num][l.FH*l.FW*l.TILE_CI+1];
    uint32_t weights_co_stride = l.FH*l.FW*l.TILE_CI+1;
    uint32_t weights_size = compute_num * weights_co_stride;

    // ofmap[2][compute_num][8];
    uint32_t ofmap_co_stride = 8;
    uint32_t ofmap_stride = compute_num * ofmap_co_stride;
    uint32_t ofmap_size = 2 * ofmap_stride;

    double *ptr = (double *)snrt_cluster_memory().start;
    double *im2col = ptr;
    ptr += im2col_size;
    double *ifmap = ptr;
    ptr += ifmap_size;
    double *weights = ptr;
    ptr += weights_size;
    double *ofmap = ptr;
    ptr += ofmap_size;
    volatile uint32_t *synch_flag = (void*)ptr;

    uint32_t write_buf = 0;
    uint32_t read_buf = 0;

    int32_t oh_prev = -1;
    int32_t ow_prev = -1;

    l.TA = 0;
    l.TB = 1;

    // snrt_global_barrier();

    benchmark_get_cycle();

    // Distribute output channels across clusters
    for (uint32_t co = cluster_id*compute_num; co < l.CO; co+=cluster_num*compute_num){

        // Tile CI dimension
        for (uint32_t ci = 0; ci < l.CI; ci+= l.TILE_CI) {

            benchmark_get_cycle();

            // Load weights in the beginning
            if (snrt_is_dm_core()) {

                snrt_dma_start_tracking();

                // Weights are stored in CO x FH x FW x CI format with additional padding
                // (CI + 1) to prevent banking conflicts
                for (uint32_t _co = 0; _co < 8; _co++) {

                    if (l.TILE_CI == l.CI) {
                        snrt_dma_txid_t weight_txid = \
                            snrt_dma_start_1d(&weights[_co * weights_co_stride], /* dst */
                                              &l.weights[(co+_co)*l.FH*l.FW*l.CI], /* src */
                                              sizeof(double)*l.CI*l.FH*l.FW /* size */);
                    }
                    else {
                        snrt_dma_txid_t weight_txid = \
                            snrt_dma_start_2d(&weights[_co * weights_co_stride], /* dst */
                                              &l.weights[(co+_co)*l.FH*l.FW*l.CI + ci], /* src */
                                              sizeof(double)*l.TILE_CI, /* size */
                                              sizeof(double)*l.TILE_CI, /* dst_stride */
                                              sizeof(double)*l.CI, /* src_stride */
                                              l.FH*l.FW /* repetitions */);
                    }
                }
                snrt_dma_wait_all();

                snrt_dma_stop_tracking();

            }
            benchmark_get_cycle();

            // Iterate over pixels, outer loop iterates over tiles of columns in feature map,
            // inner loop iterates over rows. Each core processes one pixel at a time.
            // In case of cluster2cluster communication, each cluster in a quadrant starts with a different row.
            // The first time, all clusters load a different row from memory. In each subsequent iteration
            // the leading cluster loads a new row from main memory and the others load from the next cluster
            for(uint32_t ow = 0; ow < l.OW; ow+=compute_num) {

                if (l.cluster2cluster) {
                    synch_flag[0] = 0;
                    synch_flag[1] = 0;
                }

                for (uint32_t _oh = 0; _oh < l.OH; _oh++) {

                    // If cluster2cluster is enabled, each cluster starts with a different row,
                    // requires that OH is bigger than cluster_num (per quadrant at least)
                    uint32_t oh = ((cluster_per_quadrant - 1) - (cluster_id % cluster_per_quadrant) + _oh) % l.OH;


                    if (snrt_is_dm_core()) {

                        uint32_t n_ifmap_pixel_read = min(compute_num + l.FW - 1, l.IW - ow + (l.pad<<1));
                        uint32_t n_ofmap_pixel_read = min(compute_num, l.OW - ow);
                        uint32_t n_ofmap_pixel_write = min(compute_num, l.OW - ow_prev);

                        // Load the intermediate outputs from memory
                        if (ci != 0) {
                            snrt_dma_txid_t ofmap_txid = \
                                snrt_dma_start_2d(&ofmap[write_buf * ofmap_stride], /* dst */
                                                  &l.ofmap[(oh*l.OW+ow)*l.CO + co], /* src */
                                                  sizeof(double)*8, /* size */
                                                  sizeof(double)*8, /* dst_stride */
                                                  sizeof(double)*l.CO, /* src_stride */
                                                  n_ofmap_pixel_read); /* repetitions */
                            snrt_dma_wait_all();
                        }
                        else {
                            dma_memset(&ofmap[write_buf * ofmap_stride], 0, sizeof(double) * 8 * n_ofmap_pixel_read);
                        }


                        if (l.cluster2cluster) {
                            // All except last cluster need to wait until
                            // cluster synch flag is cleared
                            if (cluster_id % cluster_per_quadrant != cluster_per_quadrant - 1) {
                                while (synch_flag[write_buf]);
                            }
                        }

                        snrt_dma_start_tracking();

                        // The input feature map needs to be loaded from main memory in the following cases:
                        // 1) cluster2cluster communication is not enabled
                        // 2) The first iteration, every cluster loads a row from main memory
                        // 3) The leading cluster always loads rows from main memory
                        if (!l.cluster2cluster || _oh == 0 || cluster_id % cluster_per_quadrant == 0) {

                            // Transfer in FH * (compute_num + FW - 1) pixels such that
                            // im2col transformation can be performed for every core

                            for (uint32_t fh = 0; fh < l.FH; fh++) {

                                // Fill horizontal lines with zeros for padding
                                if (oh + fh < l.pad || oh + fh >= l.IH + ((l.FH - 1)>>1)) {
                                    dma_memset(&ifmap[write_buf * ifmap_stride + fh * ifmap_row_stride], 0, sizeof(double)*l.TILE_CI*n_ifmap_pixel_read);
                                }
                                else {
                                    uint32_t padding_left = (ow < l.pad)? (l.pad - ow) : 0;
                                    uint32_t padding_right = (ow + compute_num + l.pad <= l.OW )? 0: n_ifmap_pixel_read - ((l.FW-1)>>1) - (l.IW - ow);

                                    // If there is need for padding, set whole buffer to zero
                                    if (padding_left || padding_right) {
                                        dma_memset(&ifmap[write_buf * ifmap_stride + fh * ifmap_row_stride], 0, sizeof(double)*(compute_num + l.FW - 1)*l.TILE_CI);
                                    }

                                    // Then fill in the rest of the values
                                    snrt_dma_txid_t ifmap_txid = \
                                        snrt_dma_start_2d(&ifmap[write_buf * ifmap_stride + fh * ifmap_row_stride + padding_left * ifmap_col_stride], /* dst */
                                                          (double*)&l.ifmap[((oh + fh - l.pad)*l.IW + ow - (l.pad - padding_left))*l.CI + ci], /* src */
                                                          sizeof(double)*l.TILE_CI, /* size */
                                                          sizeof(double)*l.TILE_CI, /* dst_stride */
                                                          sizeof(double)*l.CI, /* src_stride */
                                                          n_ifmap_pixel_read - padding_left - padding_right/* n_ifmap_pixel_read *//* repetitions */);
                                    snrt_dma_wait_all();
                                }
                            }


                        }

                        // Transfer tile from other cluster to memory
                        else {
                            // A cluster always loads from the previous cluster
                            uint32_t cluster_offset = 0x00040000;
                            volatile uint32_t *src_synch_flag = (void* )synch_flag - cluster_offset;
                            double *src_ifmap = (void* )ifmap - cluster_offset;

                            // Wait until previous cluster has released data
                            if (l.cluster2cluster && (cluster_id % cluster_per_quadrant) != 0) {
                                while(src_synch_flag[!write_buf] == 0);
                            }

                            // Transfer in FH * (compute_num + FW - 1) pixels such that
                            // im2col transformation can be performed for every core
                            snrt_dma_txid_t ifmap_txid = \
                                snrt_dma_start_1d(&ifmap[write_buf * ifmap_stride],
                                                  &src_ifmap[!write_buf * ifmap_stride],
                                                  sizeof(double)*n_ifmap_pixel_read*l.TILE_CI*l.FH);
                            snrt_dma_wait_all();

                            // clear synch flag of src cluster
                            if (l.cluster2cluster && (cluster_id % cluster_per_quadrant) != 0) {
                                // printf("Cluster %d clearing synch flag %p\n", cluster_id, &src_synch_flag[!write_buf]);
                                src_synch_flag[!write_buf] = 0;
                            }

                        }

                        snrt_dma_stop_tracking();

                        // New data is produced
                        if (l.cluster2cluster) {
                            synch_flag[write_buf] = 1;
                            // printf("Cluster %d setting synch flag %p\n", cluster_id, &synch_flag[write_buf]);
                        }

                        snrt_dma_start_tracking();

                        // Reshuffle and write data to the im2col buffer by the DMA
                        for (uint32_t n = 0; n < compute_num; n++) {

                            // only construct im2col matrix for leftover pixels
                            if (ow + n < l.OW) {

                                snrt_dma_txid_t im2col_txid = \
                                    snrt_dma_start_2d(&im2col[write_buf * im2col_mat_stride + n * im2col_row_stride], /* dst */
                                                      &ifmap[read_buf * ifmap_stride + n * ifmap_col_stride], /* src */
                                                      sizeof(double)*l.FW*l.TILE_CI, /* size */
                                                      sizeof(double)*l.FW*l.TILE_CI, /* dst_stride */
                                                      sizeof(double)*(compute_num + l.FW - 1)*l.TILE_CI, /* src_stride */
                                                      l.FH /* repetitions */);
                            }
                        }


                        // Wait for im2col transform to end, and synchronize with compute cores
                        snrt_dma_wait_all();
                        snrt_dma_stop_tracking();
                        snrt_cluster_sw_barrier();
                        benchmark_get_cycle();

                        // Transfer back the output feature maps
                        if (oh_prev + ow_prev >= 0) {

                            snrt_dma_txid_t ofmap_txid = \
                                snrt_dma_start_2d(&l.ofmap[(oh_prev*l.OW+ow_prev)*l.CO + co], /* dst */
                                                  &ofmap[!read_buf * ofmap_stride], /* src */
                                                  sizeof(double)*8, /* size */
                                                  sizeof(double)*l.CO, /* dst_stride */
                                                  sizeof(double)*8, /* src_stride */
                                                  n_ofmap_pixel_write); /* repetitions */
                            snrt_dma_wait_all();

                        }
                        oh_prev = oh;
                        ow_prev = ow;

                        // Toggle write and read buffer
                        write_buf = !write_buf;
                        read_buf = !read_buf;

                    }

                    if (snrt_is_compute_core()) {

                        // Wait until DMA core has finished the im2col transform
                        benchmark_get_cycle();
                        snrt_cluster_sw_barrier();
                        benchmark_get_cycle();

                        // Each core performs a matrix multiplication on the im2col buffer
                        // Of size (1 x FHxFWxCI) x (FHxFWxCI x 8), 8 represents CO and is the
                        // unrolling factor needed to prevent RAW conflicts.
                        if (ow + compute_id < l.OW) {

                            uint32_t setup_SSR = (ci == 0 && ow == 0 && _oh == 0)? 1 : 0;

                            if (ci != 0 && l.TILE_CI != l.CI) {
                                const uint32_t alpha = 0;
                                gemm_fp64_ssr_frep(1, 8, l.FH*l.FW*l.TILE_CI,
                                                 &im2col[read_buf * im2col_mat_stride + compute_id * im2col_row_stride], 0, l.TA,
                                                 weights, l.FH*l.FW*l.TILE_CI+1, l.TB,
                                                 &ofmap[write_buf * ofmap_stride + compute_id * ofmap_co_stride], 0, &alpha, setup_SSR);

                            }
                            else {
                                const uint32_t alpha = 1;
                                gemm_fp64_ssr_frep(1, 8, l.FH*l.FW*l.TILE_CI,
                                                   &im2col[read_buf * im2col_mat_stride + compute_id * im2col_row_stride], 0, l.TA,
                                                   weights, l.FH*l.FW*l.TILE_CI+1, l.TB,
                                                   &ofmap[write_buf * ofmap_stride + compute_id * ofmap_co_stride], 0, &alpha, setup_SSR);

                            }

                        }
                        // Toggle read and write buffer
                        read_buf = !read_buf;
                        write_buf = !write_buf;
                    }
                }
            }

            snrt_cluster_sw_barrier();


            // Transfer back last output tile
            if (snrt_is_dm_core()) {

                snrt_dma_txid_t ofmap_txid = \
                    snrt_dma_start_2d(&l.ofmap[(oh_prev*l.OW+ow_prev)*l.CO+co], /* dst */
                                      &ofmap[!read_buf * ofmap_stride], /* src */
                                      sizeof(double)*8, /* size */
                                      sizeof(double)*l.CO, /* dst_stride */
                                      sizeof(double)*8, /* src_stride */
                                      min(compute_num, l.OW - ow_prev)); /* repetitions */
                snrt_dma_wait_all();
            }
        }
    }

    // snrt_global_barrier();
}
