// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// SW testbench for profiling linear kernels in different
// floating point precisions (fp64, fp32, fp16), as well as
// different memory layouts for matrices (transposed/not-transposed)
// Correctness of results are checked automatically

#include "data_layernorm.h"
#include "layernorm_layer.h"
#include "math.h"
#include "network.h"
// #include "perf_cnt.h"
#include "snrt.h"
#include "printf.h"
#include "utils.h"

int main() {
    layernorm_l.ifmap = (float*)layernorm_ifmap_dram;
    layernorm_l.result = (float*)layernorm_ofmap_dram;

    // checksum = (float*)layernorm_checksum;

    // printf("Starting layernorm layer\n");

    layernorm_layer(&layernorm_l);

    // uint32_t error = check_layernorm_layer(&linear_l,
    // (float*)linear_checksum);

    return 0;
}