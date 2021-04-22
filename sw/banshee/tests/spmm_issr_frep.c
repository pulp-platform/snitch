// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "spmm_issr_frep.h"

#include "math.h"
#include "spmv_issr_frep_kernels.h"
#include "stdint.h"

static inline void smat16_dmat_spmm_naive(
    double* const vals_a, uint16_t* const idcs_a, uint32_t* const ptrs_a,
    uint32_t const rows_a, double* vals_b,
    uint32_t const maj_stride_b,  // e.g. CSR x DR -> DR: 1
    uint32_t const min_shift_b,   // e.g. CSR x DR -> DR: log2_cols_b
    double* res,                  // e.g. CSR x DR -> DR: rows_a X 2^min_shift_b
    uint32_t const maj_stride_res,  // e.g. CSR x DR -> DR: 1
    uint32_t const min_stride_res,  // e.g. CSR x DR -> DR: 1 << log2_cols_b
    uint32_t const maj_len_res      // e.g. CSR x DR -> DR: 1 << log2_cols_b
) {
    for (int i = 0; i < maj_len_res; ++i) {
        // Internal shiftable CsrMV loop
        double* res_loc = res;
        for (int r = 0; r < rows_a; ++r) {
            double acc = 0.0;
            for (int e = ptrs_a[r]; e < ptrs_a[r + 1]; ++e) {
                acc += vals_a[e] * vals_b[idcs_a[e] << min_shift_b];
            }
            *res_loc = acc;
            res_loc += min_stride_res;
        }
        // Advance result and dense column
        vals_b += maj_stride_b;
        res += maj_stride_res;
    }
}

static inline void smat16_dmat_spmm_opt_issr(
    double* const vals_a, uint16_t* const idcs_a, uint32_t* const ptrs_a,
    uint32_t const rows_a, double* vals_b,
    uint32_t const maj_stride_b,  // e.g. CSR x DR -> DR: 1
    uint32_t const min_shift_b,   // e.g. CSR x DR -> DR: log2_cols_b
    double* res,                  // e.g. CSR x DR -> DR: rows_a X 2^min_shift_b
    uint32_t const maj_stride_res,  // e.g. CSR x DR -> DR: 1
    uint32_t const min_stride_res,  // e.g. CSR x DR -> DR: 1 << log2_cols_b
    uint32_t const maj_len_res      // e.g. CSR x DR -> DR: 1 << log2_cols_b
) {
    // Set shift externally
    asm volatile("scfgwi %0, 1 | 12<<5" /*idx_base[1]*/ ::"r"(min_shift_b)
                 : "memory");

    // ssr_config_reg[1].idx_shift.value = min_shift_b;    // Set shift
    for (int i = 0; i < maj_len_res; ++i) {
        // Internal shiftable CsrMV loop
        smat16_dvec_spmv_opt_issr(vals_a, idcs_a, ptrs_a, rows_a, vals_b, res,
                                  min_stride_res);
        // Advance result and dense column
        vals_b += maj_stride_b;
        res += maj_stride_res;
    }
}

int32_t ilog2(uint32_t x) { return 31 - __builtin_clz(x); }

double __attribute__((section(".l1"))) res_gcc[GOLD_LEN];
double __attribute__((section(".l1"))) res_issr[GOLD_LEN];

int main() {
    double const EPS = 1e-6;
    // Run kernels
    smat16_dmat_spmm_naive(a_vals, a_idcs, a_ptrs, A_ROWS, b_vals, 1,
                           ilog2(B_COLS), res_gcc, 1, B_COLS, B_COLS);
    asm volatile("nop" ::: "memory");
    smat16_dmat_spmm_opt_issr(a_vals, a_idcs, a_ptrs, A_ROWS, b_vals, 1,
                              ilog2(B_COLS), res_issr, 1, B_COLS, B_COLS);
    // Check results
    int errors = GOLD_LEN;
    for (int i = 0; i < GOLD_LEN; ++i) {
        if (fabs(res_gcc[i] - gold_vals[i]) < EPS &&
            fabs(res_issr[i] - gold_vals[i]) < EPS)
            --errors;
    }
    return errors;
}
