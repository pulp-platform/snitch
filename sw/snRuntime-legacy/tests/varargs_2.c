// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <stdarg.h>

// Use `-O1` for this function and don't inline.
int __attribute__((noinline)) __attribute__((optimize(1)))
sum(int dummy0, int dummy1, int dummy2, int dummy3, int dummy4, int dummy5,
    int dummy6, int N, ...) {
    (void)dummy0;
    (void)dummy1;
    (void)dummy2;
    (void)dummy3;
    (void)dummy4;
    (void)dummy5;
    (void)dummy6;

    int sum = 0;
    va_list va;
    va_start(va, N);
    for (int i = 0; i < N; i++) {
        sum += va_arg(va, int);
    }
    va_end(va);
    return sum;
}

int main() {
    int e = 0;
    e += sum(0, 0, 0, 0, 0, 0, 0, 1, 1) != 1;
    e += sum(0, 0, 0, 0, 0, 0, 0, 2, 1, 2) != 1 + 2;
    e += sum(0, 0, 0, 0, 0, 0, 0, 3, 4, 5, 6) != 4 + 5 + 6;
    e += sum(0, 0, 0, 0, 0, 0, 0, 4, 2, 6, 8, 1) != 2 + 6 + 8 + 1;
    return e;
}
