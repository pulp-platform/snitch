// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "layer.h"
#include "data_conv2d.h"
#include "conv2d_layer.h"
#include "utils.h"
#include "snrt.h"
#include "math.h"
#include "printf.h"
#include "perf_cnt.h"

#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))

int main() {

    conv2d_l.ifmap = (double*)conv2d_ifmap_dram;
    conv2d_l.weights = (double*)conv2d_weights_dram;
    conv2d_l.ofmap = (double*)conv2d_ofmap_dram;
    conv2d_l.TILE_CI = min(32, conv2d_l.CI);
    conv2d_l.pad = (conv2d_l.FH-1) / 2;
    conv2d_l.cluster2cluster = 0;

    const layer l1_conv2d_l = conv2d_l;

    uint32_t cycles, dma_busy;

    if (snrt_global_core_idx() == 0) {
        snrt_reset_perf_counter(SNRT_PERF_CNT0);
        snrt_reset_perf_counter(SNRT_PERF_CNT1);
        snrt_start_perf_counter(SNRT_PERF_CNT0, SNRT_PERF_CNT_CYCLES, 0);
        snrt_start_perf_counter(SNRT_PERF_CNT1, SNRT_PERF_CNT_DMA_BUSY, 0);
    }

    conv2d_layer(l1_conv2d_l);

    if (snrt_global_core_idx() == 0) {
        snrt_stop_perf_counter(SNRT_PERF_CNT0);
        snrt_stop_perf_counter(SNRT_PERF_CNT1);

        cycles = snrt_get_perf_counter(SNRT_PERF_CNT0);
        dma_busy = snrt_get_perf_counter(SNRT_PERF_CNT1);
        // printf("perf: %d/%d dma/total\n", dma_busy, cycles);
    }

    snrt_global_barrier();

    uint32_t errors = check_layer(conv2d_l, (double*)conv2d_checksum);

    snrt_global_barrier();

    return errors;
}
