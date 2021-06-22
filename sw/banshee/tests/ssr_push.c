// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

static double x[8] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};
static double y[8];

int main() {
    __builtin_ssr_setup_1d_r(0, /*rep*/ 0, /*bound*/ 8 - 1, /*stride*/ 8,
                             /*data*/ x);
    __builtin_ssr_setup_1d_w(1, /*rep*/ 0, /*bound*/ 8 - 1, /*stride*/ 8,
                             /*data*/ y);

    // copy x to y
    __builtin_ssr_enable();
    for (int i = 0; i < 8; ++i) __builtin_ssr_push(1, __builtin_ssr_pop(0));
    __builtin_ssr_disable();

    for (int i = 0; i < 8; ++i)
        if (y[i] != x[i]) return 100 + i;

    return 0;
}
