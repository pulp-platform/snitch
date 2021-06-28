// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// An AXPY kernel using 3 SSR data movers

static double x[8] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};
static double y[8] = {10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0};
static double a = 42.0;

int main() {
    __builtin_ssr_setup_1d_r(0, /*rep*/ 0, /*bound*/ 8 - 1, /*stride*/ 8,
                             /*data*/ x);
    __builtin_ssr_setup_1d_r(1, /*rep*/ 0, /*bound*/ 8 - 1, /*stride*/ 8,
                             /*data*/ y);
    __builtin_ssr_setup_1d_w(2, /*rep*/ 0, /*bound*/ 8 - 1, /*stride*/ 8,
                             /*data*/ y);

    // copy x to y
    __builtin_ssr_enable();
    for (int i = 0; i < 8; ++i) {
        __builtin_ssr_push(2, a * __builtin_ssr_pop(0) + __builtin_ssr_pop(1));
    }
    // __builtin_ssr_barrier(2);
    __builtin_ssr_disable();

    for (int i = 0; i < 8; ++i)
        if (y[i] != a * ((double)(i + 1)) + ((double)(10 * (i + 1))))
            return 1 + i;

    return 0;
}
