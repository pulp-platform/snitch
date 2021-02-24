// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "dotp_ssr_frep.h"

#include "runtime.h"

// Assembly macros
#define SLA_FREP_ITER(max_inst, max_rep_rnum, stagger_max, stagger_mask, \
                      is_outer)                                          \
    ".word   (" #max_inst                                                \
    "<< 20) \
            |(" #max_rep_rnum                                            \
    "<< 15) \
            |(" #stagger_max                                             \
    "<< 12) \
            |(" #stagger_mask                                            \
    "<< 8)  \
            |(" #is_outer                                                \
    "<< 7)  \
            |0b0001011\n"

// Simple 1D dot product using SSRs
static inline void ssr_dvec_dvec_dotp(const double* const vals_a,
                                      const double* const vals_b,
                                      const uint32_t const len,
                                      volatile double* const res) {
    if (len == 0) return;
    const volatile register uint32_t frepCount asm("t0") = len - 1;
    asm volatile(
        // Setup zero register
        "fcvt.d.w   ft2, zero           \n"
        // SSR setup
        "sw         %[c8],  48(%[scfg]) \n"  // stride_0[0]
        "sw         %[c8], 304(%[scfg]) \n"  // stride_0[1]
        "sw         t0,     16(%[scfg]) \n"  // bounds_0[0]
        "sw         t0,    272(%[scfg]) \n"  // bounds_0[1]
        "sw         %[va], 192(%[scfg]) \n"  // rptr_0[0]
        "sw         %[vb], 448(%[scfg]) \n"  // rptr_0[1]
        // Enable SSRs
        "csrsi      0x7C0, 1            \n"
        // Init target registers
        "fmv.d      ft3, ft2            \n"
        "fmv.d      ft4, ft2            \n"
        "fmv.d      ft5, ft2            \n"
        "fmv.d      ft6, ft2            \n"
        "fmv.d      ft7, ft2            \n"
        // Computation
        SLA_FREP_ITER(0, 5, 5, 0b1001, 1)  // t0 == x5
        "fmadd.d    ft2, ft1, ft0, ft2  \n"
        // Reduction
        "fadd.d     ft9, ft6, ft7       \n"
        "fadd.d     ft6, ft4, ft5       \n"
        "fadd.d     ft7, ft2, ft3       \n"
        "fadd.d     ft4, ft6, ft7       \n"
        "fadd.d     ft8, ft4, ft9       \n"
        // Writeback
        "fsd        ft8, 0(%[res])      \n"
        // Disable SSRs
        "csrci      0x7C0, 1            \n" ::"r"(frepCount),
        [ scfg ] "r"(ssr_config_reg), [ c8 ] "r"(8), [ va ] "r"(vals_a),
        [ vb ] "r"(vals_b), [ res ] "r"(res)
        : "memory", "ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6", "ft7",
          "ft8", "ft9");
}

int main() {
    volatile double res;
    ssr_dvec_dvec_dotp(a_vals, b_vals, A_LEN, &res);
    volatile double eps = 1.0e-15;
    return !(res - gold < eps && gold - res < eps);
}
