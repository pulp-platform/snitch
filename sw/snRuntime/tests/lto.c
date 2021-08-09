// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "../../vendor/riscv-opcodes/encoding.h"
#include "lto_a.h"
#include "printf.h"

void foo4(void) { printf("Hi\n"); }

int main() {
    // The call to foo1() is optimized by the linker if LTO is enabled
    size_t t0 = read_csr(minstret);
    int res = foo1();
    size_t t1 = read_csr(minstret);

    // The number of cycles t1-t0
    //       non-LTO   LTO
    // gcc     6        1
    // llvm    1       13
    // printf("instret: %d\n", t1-t0);
    return (t1 - t0 - 1);
}
