// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

int main() {
    double x = 0;
    volatile register int rpt_max asm("t0") = 3;
    asm volatile(
        ".word (1 << 20)|(5 << 15)|(1 << 7)|(0b0001011 << 0) \n"  // frep t0, 2
        "fadd.d %0, %0, %1\n"
        "fmul.d %0, %0, %2\n"
        : "+f"(x)
        : "f"(1.0), "f"(2.0), "r"(rpt_max));
    return x != 30;
}
