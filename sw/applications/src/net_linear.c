// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// SW testbench for profiling linear kernels in different
// floating point precisions (fp64, fp32, fp16), as well as
// different memory layouts for matrices (transposed/not-transposed)
// Correctness of results are checked automatically

#include "data_linear.h"
#include "math.h"
#include "network.h"
#include "linear_layer.h"
#include "perf_cnt.h"
#include "printf.h"
#include "snrt.h"
#include "utils.h"

int main() {
    linear_l.ifmap = (float*)linear_ifmap_dram;
    linear_l.weights = (float*)linear_weights_dram;
    linear_l.bias = (float*)linear_bias_dram;
    linear_l.result = (float*)linear_ofmap_dram;

    linear_layer(&linear_l);

    // uint32_t error = check_linear_layer(&linear_l, (float*)linear_checksum);

    return 0;
}