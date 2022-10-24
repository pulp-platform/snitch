// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "layer.h"
#include "maxpool_layer.h"
#include "maxpool.h"
#include "snrt.h"
#include "printf.h"

void maxpool_layer(layer l) {

    uint32_t cluster_num = snrt_cluster_num();
    uint32_t cluster_id = snrt_cluster_idx();
    uint32_t compute_num = snrt_cluster_compute_core_num();
    uint32_t compute_id = snrt_cluster_compute_core_idx();

    // Each cluster loads one tile of kernel size
    uint32_t ifmap_size = 2 * l.FH * l.FW * l.TILE_CI;
    uint32_t ofmap_size = 2 * l.TILE_CI;

    double *ptr = (double*)snrt_cluster_memory().start;
    double *ifmap = ptr;
    ptr += ifmap_size;
    double *ofmap = ptr;
    ptr += ofmap_size;

    uint32_t read_buf = 0;
    uint32_t write_buf = 0;

    uint32_t prev_oh;
    uint32_t prev_ow;
    uint32_t prev_ci;

    // tiles are distributed across clusters
    for (uint32_t tile = cluster_id; tile < l.OH * l.OW; tile+=cluster_num) {

        for (uint32_t ci = 0; ci < l.CI; ci+=l.TILE_CI) {

            uint32_t oh = tile / l.OW;
            uint32_t ow = tile % l.OW;

            if (snrt_is_dm_core()) {

                for (uint32_t fh = 0; fh < l.FH; fh++) {

                    if (l.TILE_CI == l.CI) {
                        snrt_dma_start_1d(&ifmap[write_buf * (ifmap_size/2) + fh * l.FW * l.TILE_CI], /* dst */
                                      &l.ifmap[((oh * l.FH + fh) * l.IW + ow * l.FW)*l.CI], /* src */
                                      sizeof(double) * l.TILE_CI * l.FW /* size */);
                    }
                    else {
                        // printf("bubu\n");
                        snrt_dma_start_2d(&ifmap[write_buf * (ifmap_size/2) + fh * l.FW * l.TILE_CI], /* dst */
                                          &l.ifmap[((oh * l.FH + fh) * l.IW + ow * l.FW)*l.CI + ci], /* src */
                                          sizeof(double) * l.TILE_CI, /* size */
                                          sizeof(double) * l.TILE_CI, /* dst_stride */
                                          sizeof(double) * l.CI, /* src_stride */
                                          l.FW /* repetitions */);
                    }
                }
                snrt_dma_wait_all();

                // synchronize with compute cores after loading data
                snrt_cluster_sw_barrier();

                if (!(tile == cluster_id && ci == 0)) {

                    snrt_dma_start_2d(&l.ofmap[(prev_oh * l.OW + prev_ow)*l.CI + prev_ci], /* dst */
                                      &ofmap[!read_buf * (ofmap_size/2)], /* src */
                                      sizeof(double) * l.TILE_CI, /* size */
                                      sizeof(double) * l.CI, /* dst_stride */
                                      sizeof(double) * l.TILE_CI, /* src_stride */
                                      1 /* repetitions */);


                }

                snrt_dma_wait_all();
                write_buf = !write_buf;
                read_buf = !read_buf;
                prev_ci = ci;
                prev_oh = oh;
                prev_ow = ow;
            }

            if (snrt_is_compute_core()) {

                // wait for data to arrive
                snrt_cluster_sw_barrier();

                maxpool_fp64(&ifmap[read_buf * ifmap_size/2 + compute_id],
                             &ofmap[write_buf * ofmap_size/2 + compute_id],
                             l.TILE_CI,
                             l.FH,
                             l.FW,
                             compute_num);

                write_buf = !write_buf;
                read_buf = !read_buf;
            }

        }
    }

    snrt_cluster_sw_barrier();

    if (snrt_is_dm_core()) {

        snrt_dma_start_2d(&l.ofmap[(prev_oh * l.OW + prev_ow)*l.CI + prev_ci], /* dst */
                          &ofmap[!read_buf * (ofmap_size/2)], /* src */
                          sizeof(double) * l.TILE_CI, /* size */
                          sizeof(double) * l.CI, /* dst_stride */
                          sizeof(double) * l.TILE_CI, /* src_stride */
                          1 /* repetitions */);
    }

    snrt_dma_wait_all();

}
