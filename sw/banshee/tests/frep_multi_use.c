// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

int main() {
    double x = 0, y = 0, z = 0;
    volatile register int rpt_max_1 asm("t0") = 3;
    volatile register int rpt_max_2 asm("t1") = 7;
    asm volatile(
        ".word (1 << 20)|(5 << 15)|(1 << 7)|(0b0001011 << 0) \n"  // frep t0, 2
        "fadd.d %0, %0, %3\n"
        "fmul.d %0, %0, %4\n"
        ".word (1 << 20)|(6 << 15)|(1 << 7)|(0b0001011 << 0) \n"  // frep t1, 2
        "fadd.d %1, %1, %3\n"
        "fmul.d %1, %1, %4\n"
        "fsub.d %2, %1, %0\n"
        : "+f"(x), "+f"(y), "+f"(z)
        : "f"(1.0), "f"(2.0), "r"(rpt_max_1), "r"(rpt_max_2)
        : "a0");
    return z != 480;
}
