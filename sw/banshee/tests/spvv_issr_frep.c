// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "spvv_issr_frep.h"

#include "math.h"
#include "stdint.h"

// Naive compiled SpVV kernel
static inline void svec16_dvec_dotp_naive(double* const vals_a,
                                          uint16_t* const idcs_a,
                                          uint32_t const len_a,
                                          double* const vals_b,
                                          double* const res) {
    double acc = 0.0;
    for (int i = 0; i < len_a; ++i) {
        acc += vals_a[i] * vals_b[idcs_a[i]];
    }
    *res = acc;
}

// Optimized assembly kernel using ISSR + SSR
static inline void svec16_dvec_dotp_opt_issr(const double* vals_a,
                                             const uint16_t* idcs_a,
                                             const uint32_t len_a,
                                             const double* const vals_b,
                                             volatile double* const res) {
    if (len_a == 0) return;
    // Assembly kernel
    asm volatile(
        // Setup zero register
        "fcvt.d.w   ft2, zero           \n"
        // SSR setup
        "scfgwi %[ldec], 0 |  2<<5      \n"  // bounds_0[0]
        "scfgwi %[ldec], 1 |  2<<5      \n"  // bounds_0[1]
        "scfgwi %[c8],   0 |  6<<5      \n"  // stride_0[0]
        "scfgwi %[c8],   1 |  6<<5      \n"  // stride_0[1]
        "scfgwi %[c1],   1 | 10<<5      \n"  // idx_size[1]
        "scfgwi %[valb], 1 | 11<<5      \n"  // idx_base[1]
        "scfgwi %[vala], 0 | 24<<5      \n"  // rptr_0[0]
        "scfgwi %[idca], 1 | 16<<5      \n"  // rptr_indir[1]
        // Enable SSRs
        "csrsi      0x7C0, 1            \n"
        // Init target registers
        "fmv.d      ft3, ft2            \n"
        "fmv.d      ft4, ft2            \n"
        "fmv.d      ft5, ft2            \n"
        "fmv.d      ft6, ft2            \n"
        "fmv.d      ft7, ft2            \n"
        // Computation
        "frep.o %[ldec], 1, 5, 0b1001   \n"
        "fmadd.d    ft2, ft1, ft0, ft2  \n"
        // Reduction
        "fadd.d     ft9, ft6, ft7       \n"
        "fadd.d     ft6, ft4, ft5       \n"
        "fadd.d     ft7, ft2, ft3       \n"
        "fadd.d     ft4, ft6, ft7       \n"
        "fadd.d     ft8, ft4, ft9       \n"
        // Writeback
        "fsd        ft8, 0(%[res])      \n"
        // Fence, disable SSRs
        "fmv.x.w    t0, fa0             \n"
        "csrci      0x7C0, 1            \n"
        "bne t0,    zero, 9f            \n9:" ::[res] "r"(res),
        [ c8 ] "r"(8), [ c1 ] "r"(1), [ vala ] "r"(vals_a),
        [ idca ] "r"(idcs_a), [ valb ] "r"(vals_b), [ ldec ] "r"(len_a - 1)
        : "memory", "t0", "ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6",
          "ft7", "ft8", "ft9");
}

int main() {
    double res_issr, res_gcc;
    double const EPS = 1e-6;
    // Run kernels
    svec16_dvec_dotp_naive(a_vals, a_idcs, A_DATA_LEN, b_vals, &res_gcc);
    svec16_dvec_dotp_opt_issr(a_vals, a_idcs, A_DATA_LEN, b_vals, &res_issr);
    // Check results
    return (fabs(res_gcc - gold) > EPS || fabs(res_issr - gold) > EPS);
}
