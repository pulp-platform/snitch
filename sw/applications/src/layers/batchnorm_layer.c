// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "layer.h"
#include "batchnorm_layer.h"
#include "batchnorm.h"
#include "snrt.h"

void batchnorm_layer(layer l) {

    uint32_t cluster_num = snrt_cluster_num();
    uint32_t cluster_id = snrt_cluster_idx();
    uint32_t compute_num = snrt_cluster_compute_core_num();
    uint32_t compute_id = snrt_cluster_compute_core_idx();

    // Each cluster loads one tile of a row
    uint32_t ifmap_size = 2 * l.IW * l.TILE_CI;
    uint32_t weights_size = l.CI;
    uint32_t ofmap_size = 2 * l.IW * l.TILE_CI;

    double *ptr = (double *)snrt_cluster_memory().start;
    double *ifmap = ptr;
    ptr += ifmap_size;
    double *gamma = ptr;
    ptr += weights_size;
    double *beta = ptr;
    ptr += weights_size;
    double *ofmap = ptr;
    ptr += ofmap_size;

    uint32_t read_buf = 0;
    uint32_t write_buf = 0;

    uint32_t prev_oh;
    uint32_t prev_ow;
    uint32_t prev_ci;

    for (uint32_t oh = cluster_id; oh < l.OH; oh+=cluster_num) {
        for (uint32_t ci = 0; ci < l.CI; ci+=l.TILE_CI) {

            if (snrt_is_dm_core()) {

                // Load weights once in the beginning
                if (oh == cluster_id && ci == 0) {
                    snrt_dma_start_1d(gamma, l.gamma, sizeof(double) * l.CI);
                    snrt_dma_start_1d(beta, l.beta, sizeof(double) * l.CI);
                    snrt_dma_wait_all();
                }

                // Load some stuff
                if (l.TILE_CI == l.CI) {
                    // data layout is consecutively in memory
                    snrt_dma_start_1d(&ifmap[write_buf * ifmap_size/2], &l.ifmap[oh * l.IW * l.CI], sizeof(double) * l.IW * l.TILE_CI);
                }
                else {
                    // data is interleaved
                    snrt_dma_start_2d(&ifmap[write_buf * ifmap_size/2], /* dst */
                                      &l.ifmap[oh * l.IW * l.CI + ci], /* src */
                                      sizeof(double) * l.TILE_CI,       /* size */
                                      sizeof(double) * l.TILE_CI,       /* dst_stride */
                                      sizeof(double) * l.CI,            /* src_stride */
                                      l.IW);                            /* repetitions */
                }

                snrt_dma_wait_all();

                snrt_cluster_sw_barrier();

                if (!(oh == cluster_id && ci == 0)) {

                    if (l.TILE_CI == l.CI) {
                        // data is stored consecutively
                        snrt_dma_start_1d(&l.ofmap[prev_oh * l.OW * l.CI], &ofmap[!read_buf * (ofmap_size/2)], sizeof(double) * l.IW * l.CI);
                    }
                    else {
                        // data is stored in interleaved layout
                        snrt_dma_start_2d(&l.ofmap[prev_oh * l.OW * l.CI + prev_ci], /* dst */
                                          &ofmap[!read_buf * (ofmap_size/2)],   /* src */
                                          sizeof(double) * l.TILE_CI,           /* size */
                                          sizeof(double) * l.CI,                /* dst_stride */
                                          sizeof(double) * l.TILE_CI,           /* src_stride */
                                          l.IW);                                /* repetitions */
                    }
                }

                snrt_dma_wait_all();
                write_buf = !write_buf;
                read_buf = !read_buf;
                prev_ci = ci;
                prev_oh = oh;
                /* prev_ow = ow; */
            }

            if (snrt_is_compute_core()) {

                // Wait for data
                snrt_cluster_sw_barrier();
                // initially setup SSRs
                uint32_t setup_SSR = (oh == cluster_id && ci == 0);

                // Start kernel
                batchnorm_fp64(&ifmap[read_buf * ofmap_size/2 + compute_id],
                    &gamma[ci + compute_id],
                    &beta[ci + compute_id],
                    &ofmap[write_buf * ofmap_size/2 + compute_id],
                    l.OW,
                    l.TILE_CI,
                    compute_num,
                    setup_SSR);

                write_buf = !write_buf;
                read_buf = !read_buf;
            }
        }
    }

    snrt_cluster_sw_barrier();

    // Store last tile back
    if (snrt_is_dm_core()) {

        if (l.TILE_CI == l.CI) {
            // data is stored consecutively
            snrt_dma_start_1d(&l.ofmap[prev_oh * l.OW * l.CI], &ofmap[!read_buf * (ofmap_size/2)], sizeof(double) * l.IW * l.CI);
        }
        else {
            // data is stored in interleaved layout
            snrt_dma_start_2d(&l.ofmap[prev_oh * l.OW * l.CI + prev_ci], /* dst */
                              &ofmap[!read_buf * (ofmap_size/2)],   /* src */
                              sizeof(double) * l.TILE_CI,           /* size */
                              sizeof(double) * l.CI,                /* dst_stride */
                              sizeof(double) * l.TILE_CI,           /* src_stride */
                              l.IW);                                /* repetitions */
        }

        snrt_dma_wait_all();
    }
}
