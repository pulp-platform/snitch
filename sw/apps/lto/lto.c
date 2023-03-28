// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "lto_a.h"
#include "snrt.h"

void foo4(void) { printf("Hi\n"); }

int main() {
    // The call to foo1() is optimized by the linker if LTO is enabled
    // so the number of cycles t1-t0 should be 1
    size_t t0 = read_csr(minstret);
    int res = foo1();
    size_t t1 = read_csr(minstret);

    return (t1 - t0 - 1);
}
