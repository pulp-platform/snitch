// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

int main() {
#pragma GCC unroll 1024
    for (int i = 0; i < 1024; i++) {
        asm volatile("nop");
    }

    return 0;
}
