// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// SW testbench for profiling linear kernels in different
// floating point precisions (fp64, fp32, fp16), as well as
// different memory layouts for matrices (transposed/not-transposed)
// Correctness of results are checked automatically

#include "data_fp32_nnlinear.h"
#include "math.h"
#include "network.h"
#include "nnlinear_backend_baseline.h"
// #include "perf_cnt.h"
#include "printf.h"
#include "snrt.h"
#include "utils.h"

int main() {
    nn_linear_baseline_t.W = (void *)nn_linear_baseline_weights_dram;
    nn_linear_baseline_t.b = (void *)nn_linear_baseline_biases_dram;

    // Run the baseline neural network
    nnlinear_backend_baseline(&nn_linear_baseline_t);
    snrt_global_barrier();

    return 0;
}