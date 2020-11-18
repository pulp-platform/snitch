// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

int main() {
    double x = 0;
    volatile register int N asm ("t0") = 4;
    asm volatile (
        ".word (0 << 20)|(5 << 15)|(1 << 7)|(0b0001011 << 0) \n" // frep t0, 1
        // "frep.o %2, 1 \n"
        "fadd.d %0, %0, %1 \n"
        : "+f"(x) : "f"(1.0),"r"(N)
    );
    return x != N+1;
}
