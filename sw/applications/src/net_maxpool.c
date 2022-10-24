// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "layer.h"
#include "data_maxpool.h"
#include "maxpool_layer.h"
#include "utils.h"
#include "snrt.h"
#include "math.h"
#include "printf.h"

int main() {

    maxpool_l.ifmap = (double*)maxpool_ifmap_dram;
    maxpool_l.ofmap = (double*)maxpool_ofmap_dram;
    maxpool_l.TILE_CI = 32;

    maxpool_layer(maxpool_l);

    snrt_global_barrier();

    uint32_t error = check_layer(maxpool_l, (double*)maxpool_checksum);

    snrt_global_barrier();

    return error;
}
