// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

static double x[8] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};
static double y[8] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};

int main() {
    // __builtin_ssr_setup_1d(0,rep 0,/*bound*/ 8-1, /*stride*/ 8, /*data*/ x);
    __builtin_ssr_setup_1d_r(0, /*rep*/ 0, /*bound*/ 8 - 1, /*stride*/ 8,
                             /*data*/ x);
    __builtin_ssr_setup_1d_r(1, /*rep*/ 0, /*bound*/ 8 - 1, /*stride*/ 8,
                             /*data*/ y);

    __builtin_ssr_enable();

    volatile double tmp;
    unsigned ret;
    asm volatile(
        // this should read consecutives elements from x
        "fsgnj.d %[tmp], ft0, ft0\n"
        "fld     ft3, 0(%[x])\n"
        "feq.d   t1, %[tmp], ft3\n"
        "beq     t1, zero, 1f\n"

        "fsgnj.d %[tmp], ft0, ft0\n"
        "fld     ft3, 8(%[x])\n"
        "feq.d   t1, %[tmp], ft3\n"
        "beq     t1, zero, 1f\n"

        "fsgnj.d %[tmp], ft0, ft0\n"
        "fld     ft3, 16(%[x])\n"
        "feq.d   t1, %[tmp], ft3\n"
        "beq     t1, zero, 1f\n"

        "fsgnj.d %[tmp], ft0, ft0\n"
        "fld     ft3, 24(%[x])\n"
        "feq.d   t1, %[tmp], ft3\n"
        "beq     t1, zero, 1f\n"

        // this should read consecutives elements from y
        "fsgnj.d %[tmp], ft1, ft1\n"
        "fld     ft3, 0(%[y])\n"
        "feq.d   t1, %[tmp], ft3\n"
        "beq     t1, zero, 1f\n"

        "fsgnj.d %[tmp], ft1, ft1\n"
        "fld     ft3, 8(%[y])\n"
        "feq.d   t1, %[tmp], ft3\n"
        "beq     t1, zero, 1f\n"

        "fsgnj.d %[tmp], ft1, ft1\n"
        "fld     ft3, 16(%[y])\n"
        "feq.d   t1, %[tmp], ft3\n"
        "beq     t1, zero, 1f\n"

        "fsgnj.d %[tmp], ft1, ft1\n"
        "fld     ft3, 24(%[y])\n"
        "feq.d   t1, %[tmp], ft3\n"
        "beq     t1, zero, 1f\n"

        // same with frep
        // This is a good example on where this behaviour is useful:
        // element-wise square and add a vector
        "li t0, 4-1\n"
        "fcvt.d.w %[tmp], x0\n"
        "frep.o t0, 1, 0, 0b0000\n"
        "fmadd.d %[tmp], ft0, ft0, %[tmp]\n"
        "feq.d   t1, %[tmp], %[prod_x]\n"
        "beq     t1, zero, 1f\n"

        // same for ft1
        // this also verifies that frep can be issued mutliple times
        "li t0, 4-1\n"
        "fcvt.d.w %[tmp], x0\n"
        "frep.o t0, 1, 0, 0b0000\n"
        "fmadd.d %[tmp], ft1, ft1, %[tmp]\n"
        "feq.d   t1, %[tmp], %[prod_y]\n"
        "beq     t1, zero, 1f\n"

        "li %[ret], 0\n"  // no error, load 0
        "j 2f\n"

        "1:\n"  // error
        "li %[ret], 1\n"

        "2:\n"  // no error
        : [ tmp ] "+fr"(tmp), [ ret ] "+r"(ret)
        :
        [ x ] "r"(x), [ y ] "r"(y),
        [ prod_x ] "fr"(x[4] * x[4] + x[5] * x[5] + x[6] * x[6] + x[7] * x[7]),
        [ prod_y ] "fr"(y[4] * y[4] + y[5] * y[5] + y[6] * y[6] + y[7] * y[7])
        : "ft0", "ft1", "ft3", "t0", "t1");
    __builtin_ssr_disable();

    return ret;
}
