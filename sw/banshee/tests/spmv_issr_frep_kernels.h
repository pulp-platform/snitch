// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "stdint.h"

static inline void smat16_dvec_spmv_naive(
    double* const vals_a, uint16_t* const idcs_a, uint32_t* const ptrs_a,
    uint32_t const rows_a, double* const vals_b, double* const res) {
    for (int r = 0; r < rows_a; ++r) {
        double acc = 0.0;
        for (int e = ptrs_a[r]; e < ptrs_a[r + 1]; ++e) {
            acc += vals_a[e] * vals_b[idcs_a[e]];
        }
        res[r] = acc;
    }
}

static inline void smat16_dvec_spmv_opt_issr(
    const double* const vals_a, const uint16_t* const idcs_a,
    const uint32_t* ptrs_a, const uint32_t rows_a, const double* const vals_b,
    double* res, const uint32_t stride_res) {
    // Load and check bounds
    if (rows_a == 0) return;
    const uint32_t* rlst = ptrs_a + rows_a;
    const uint32_t roffs_first = *ptrs_a;
    const uint32_t roffs_last = *rlst;
    if (roffs_first == roffs_last) return;
    // SSR setup: in separate block to optimize register allocation
    asm volatile(
        "sub        t0, %[olst], %[ofst]\n"
        "addi       t0, t0, -1          \n"  // nnz-1
        "scfgwi     t0, 0 |  2<<5       \n"  // bounds_0[0]
        "scfgwi     t0, 1 |  2<<5       \n"  // bounds_0[1]
        "scfgwi     %[c8], 0 |  6<<5    \n"  // stride_0[0]
        "scfgwi     %[c8], 1 |  6<<5    \n"  // stride_0[1]
        "scfgwi     %[c1], 1 | 10<<5    \n"  // idx_size[1]
        "scfgwi     %[valb], 1 | 11<<5  \n"  // idx_base[1]
        "slli       t0, %[ofst], 1      \n"
        "add        t0, %[idca], t0     \n"  // offset indices to first row
        "scfgwi     t0, 1 | 16<<5       \n"  // rptr_indir[1]
        "slli       t0, %[ofst], 3      \n"
        "add        t0, %[vala], t0     \n"  // Offset values to first row
        "scfgwi     t0, 0 | 24<<5       \n"  // rptr_0[0]
        ::[vala] "r"(vals_a),
        [ idca ] "r"(idcs_a), [ valb ] "r"(vals_b), [ ofst ] "r"(roffs_first),
        [ olst ] "r"(roffs_last), [ c1 ] "r"(1), [ c8 ] "r"(8)
        : "memory", "t0");
    // Computation
    asm volatile(
        // Preload ptrs_a[0], reset base accumulator
        "lw         t4, 0(%[rptr])      \n"
        "fmv.d      ft3, %[f0]          \n"
        // Enable SSRs
        "csrsi      0x7C0, 1            \n"
        "j          20f                 \n"
        // Joint reentry points for loop
        "10:"  // Reentry with row result in ft9
        "fsd        ft9, 0 (%[res])     \n"
        "11:"  // Reentry with row result already stored
        "add        %[res], %[res], %[rstr]\n"
        // Row loop
        "20:"
        "lw         t5, 4(%[rptr])      \n"
        "ble        t5, t4, 0f          \n"  // ptrs_a[r+1] == ptrs_a[r] -->
                                             // empty
        "addi       %[rptr], %[rptr], 4 \n"
        "sub        t6, t5, t4          \n"
        "mv         t4, t5              \n"
        "fmadd.d    ft4, ft1, ft0, %[f0]\n"
        "beq        t6, %[c1], 1f       \n"  // ptrs_a[r+1] == ptrs_a[r] + 1 -->
                                             // 1 elem
        "fmadd.d    ft5, ft1, ft0, %[f0]\n"
        "beq        t6, %[c2], 2f       \n"  // ptrs_a[r+1] == ptrs_a[r] + 2 -->
                                             // 2 elems
        "fmadd.d    ft6, ft1, ft0, %[f0]\n"
        "beq        t6, %[c3], 3f       \n"  // ptrs_a[r+1] == ptrs_a[r] + 3 -->
                                             // 3 elems
        "fmadd.d    ft7, ft1, ft0, %[f0]\n"
        "beq        t6, %[c4], 4f       \n"  // ptrs_a[r+1] == ptrs_a[r] + 4 -->
                                             // 4 elems
        "fmadd.d    fs0, ft1, ft0, %[f0]\n"
        "beq        t6, %[c5], 5f       \n"  // ptrs_a[r+1] == ptrs_a[r] + 5 -->
                                             // 5 elems
        // If more than 5 elements: commit to FREP
        "addi       t6, t6, -6          \n"
        "frep.o     t6, 1, 5, 0b1001    \n"
        "fmadd.d    ft3, ft1, ft0, ft3  \n"
        "fadd.d     ft10, ft7, fs0      \n"
        "fadd.d     ft7, ft5, ft6       \n"
        "fadd.d     fs0, ft3, ft4       \n"
        "fadd.d     ft5, ft7, fs0       \n"
        "fmv.d      ft3, %[f0]          \n"  // Reset reg ft3 used only in full
                                             // loop
        "fadd.d     ft9, ft5, ft10       \n"
        "bne        %[rptr], %[rlst], 10b\n"
        "j          30f                 \n"
        // 5 elems
        "5:"
        "fadd.d     ft10, ft4, ft5      \n"
        "fadd.d     ft4, ft6, ft7       \n"
        "fadd.d     ft5, ft10, fs0      \n"
        "fadd.d     ft9, ft5, ft4       \n"
        "bne        %[rptr], %[rlst], 10b\n"
        "j          30f                 \n"
        // 4 elems
        "4:"
        "fadd.d     ft10, ft4, ft5      \n"
        "fadd.d     ft4, ft6, ft7       \n"
        "fadd.d     ft9, ft4, ft10       \n"
        "bne        %[rptr], %[rlst], 10b\n"
        "j          30f                 \n"
        // 3 elems
        "3:"
        "fadd.d     ft7, ft4, ft5       \n"
        "fadd.d     ft9, ft6, ft7       \n"
        "bne        %[rptr], %[rlst], 10b\n"
        "j          30f                 \n"
        // 2 elems
        "2:"
        "fadd.d     ft9, ft4, ft5       \n"
        "bne        %[rptr], %[rlst], 10b\n"
        "j          30f                 \n"
        // 1 elem
        "1:"
        "fsd        ft4, 0 (%[res])     \n"
        "bne        %[rptr], %[rlst], 11b\n"
        "j          30f                 \n"
        // empty
        "0:"
        "fsd        %[f0], 0 (%[res])   \n"
        "bne        %[rptr], %[rlst], 11b\n"
        // Fence, disable SSRs
        "30:"
        "fmv.x.w    t0, fa0             \n"
        "csrci      0x7C0, 1            \n"
        "bne t0,    zero, 9f            \n9:"
        : [ rptr ] "+&r"(ptrs_a), [ res ] "+&r"(res), [ rlst ] "+&r"(rlst)
        : [ c1 ] "r"(1), [ c2 ] "r"(2), [ c3 ] "r"(3), [ c4 ] "r"(4),
          [ c5 ] "r"(5), [ f0 ] "f"(0.0),
          [ rstr ] "r"(stride_res << 3)  // inputs
        : "memory", "t4", "t5", "t6", "ft0", "ft1", "ft2", "ft3", "ft4", "ft5",
          "ft6", "ft7", "fs0", "ft9", "ft10");
}
