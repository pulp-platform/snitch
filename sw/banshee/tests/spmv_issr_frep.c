// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "spmv_issr_frep.h"

#include "math.h"
#include "spmv_issr_frep_kernels.h"
#include "stdint.h"

double __attribute__((section(".l1"))) res_gcc[A_ROWS];
double __attribute__((section(".l1"))) res_issr[A_ROWS];

int main() {
    double const EPS = 1e-6;
    // Run kernels
    smat16_dvec_spmv_naive(a_vals, a_idcs, a_ptrs, A_ROWS, b_vals, res_gcc);
    smat16_dvec_spmv_opt_issr(a_vals, a_idcs, a_ptrs, A_ROWS, b_vals, res_issr,
                              1);
    // Check results
    int errors = A_ROWS;
    for (int i = 0; i < A_ROWS; ++i) {
        if (fabs(res_gcc[i] - gold_vals[i]) < EPS &&
            fabs(res_issr[i] - gold_vals[i]) < EPS)
            --errors;
    }
    return errors;
}
