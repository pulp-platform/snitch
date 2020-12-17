// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

int main() {
    volatile register double x asm("ft0") = 0.0;
    volatile register int rpt_max asm("t0") = 3;
    asm volatile(
        // Stagger rd and rs1
        ".word (1 << 20)|(5 << 15)|(4 << 12)|(0b0011 << 8)|(1 << 7)|(0b0001011 "
        "<< 0) \n"
        "fadd.d ft0, ft0, %1\n"
        "fmul.d ft1, ft0, %2\n"
        "fmv.d ft0, ft4"
        : "+f"(x)
        : "f"(1.0), "f"(2.0), "r"(rpt_max)
        : "ft1", "ft2", "ft3", "ft4", "ft5", "ft6");
    return x != 30;
}
