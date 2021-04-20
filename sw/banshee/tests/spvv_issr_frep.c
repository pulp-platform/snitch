// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "spvv_issr_frep.h"

#include <stdint.h>

#include "math.h"
#include "runtime.h"

// FREP assembly macro
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
static inline void svec16_dvec_dotp_opt_issr(double* vals_a, uint16_t* idcs_a,
                                             uint32_t const len_a,
                                             double* const vals_b,
                                             double* const res) {
    if (len_a == 0) return;
    asm volatile (
        // SSR setup
        // TODO: Use SSR extensions, shared config write here once available
        "fmv.d      ft2, %[f0]          \n"     // Pull ahead to prevent bubble
        "li         t0, 8               \n"
        "li         t1, 1               \n"
        "mv         t6, %2              \n"     // Use for FREP later
        "sw         t6, 16 (%5)         \n"     // bounds[0]
        "sw         t6, 282(%5)         \n"     // bounds[1]
        "sw         t1, 336(%5)         \n"     // idx_size[1]
        "sw         %3, 344(%5)         \n"     // idx_base[1]
        "sw         t0, 48 (%5)         \n"     // stride_0[0]
        "sw         t0, 304(%5)         \n"     // stride_1[0]
        "sw         %1, 384(%5)         \n"     // rptr_indir[1]
        "sw         %0, 192(%5)         \n"     // rptr_0[0]
        // Enable SSRs
        "csrsi      0x7C0, 1            \n"
        // Init target registers
        "fmv.d      ft3, ft2            \n"
        "fmv.d      ft4, ft2            \n"
        "fmv.d      ft5, ft2            \n"
        "fmv.d      ft6, ft2            \n"
        "fmv.d      ft7, ft2            \n"
        // Computation
        SLA_FREP_ITER(0,31,5,0b1001,1)
        "fmadd.d    ft2, ft1, ft0, ft2  \n"
        // Reduction
        "fadd.d     ft9, ft6, ft7       \n"
        "fadd.d     ft6, ft4, ft5       \n"
        "fadd.d     ft7, ft2, ft3       \n"
        "fadd.d     ft4, ft6, ft7       \n"
        "fadd.d     ft8, ft4, ft9       \n"
        // Writeback
        "fsd        ft8, 0(%4)          \n"
        // Fence, disable SSR
        "fmv.x.w    t0, fa0             \n"
        "csrci      0x7C0, 1            \n"
        "bne t0,    zero, 9f            \n9:"
        ::  "r"(vals_a), "r"(idcs_a), "r"(len_a-1),
            "r"(vals_b), "r"(res), "r"(ssr_config_reg), [f0]"f"(0.0)
        : "memory", "t0", "t1", "t6", "ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6", "ft7", "ft8", "ft9"
    );
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
