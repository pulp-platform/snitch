// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

int main() {
    volatile double f_rd;
    volatile unsigned int d_rd;

    d_rd = 0x42298a3d;  // = 42.384998321533203125

    asm volatile(
        "fmv.w.x %1, x0\n"  // float = 0
        "fmv.w.x %1, %0\n"  // float <- int

        "mv      %0, x0\n"  // int   = 0
        "fmv.x.w %0, %1\n"  // int   <- float

        : "+r"(d_rd), "+f"(f_rd));

    return 0;
}
