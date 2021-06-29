// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "dotp_ssr_frep.h"

#include "stdint.h"

// Simple 1D dot product using SSRs
static inline void ssr_dvec_dvec_dotp(const double* const vals_a,
                                      const double* const vals_b,
                                      const uint32_t len,
                                      volatile double* const res) {
    if (len == 0) return;
    asm volatile(
        // Setup zero register
        "fcvt.d.w   ft3, zero           \n"
        // SSR setup
        "scfgwi %[ldec], 0 |  2<<5      \n"  // bounds_0[0]
        "scfgwi %[ldec], 1 |  2<<5      \n"  // bounds_0[1]
        "scfgwi %[c8],   0 |  6<<5      \n"  // stride_0[0]
        "scfgwi %[c8],   1 |  6<<5      \n"  // stride_0[1]
        "scfgwi %[vala], 0 | 24<<5      \n"  // rptr_0[0]
        "scfgwi %[valb], 1 | 24<<5      \n"  // rptr_0[1]
        // Enable SSRs
        "csrsi      0x7C0, 1            \n"
        // Init target registers
        "fmv.d      ft4, ft3            \n"
        "fmv.d      ft5, ft3            \n"
        "fmv.d      ft6, ft3            \n"
        "fmv.d      ft7, ft3            \n"
        "fmv.d      fs0, ft3            \n"
        // Computation
        "frep.o %[ldec], 1, 5, 0b1001   \n"
        "fmadd.d    ft3, ft1, ft0, ft3  \n"
        // Reduction
        "fadd.d     ft9, ft6, ft7       \n"
        "fadd.d     ft6, ft4, ft5       \n"
        "fadd.d     ft7, fs0, ft3       \n"
        "fadd.d     ft4, ft6, ft7       \n"
        "fadd.d     ft8, ft4, ft9       \n"
        // Writeback
        "fsd        ft8, 0(%[res])      \n"
        // Fence, disable SSRs
        "fmv.x.w    t0, fa0             \n"
        "csrci      0x7C0, 1            \n"
        "bne t0,    zero, 9f            \n9:" ::[res] "r"(res),
        [ c8 ] "r"(8), [ vala ] "r"(vals_a), [ valb ] "r"(vals_b),
        [ ldec ] "r"(len - 1)
        : "memory", "t0", "ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6",
          "ft7", "ft8", "ft9", "fs0");
}

int main() {
    volatile double res;
    ssr_dvec_dvec_dotp(a_vals, b_vals, A_LEN, &res);
    volatile double eps = 1.0e-15;
    return !(res - gold < eps && gold - res < eps);
}
