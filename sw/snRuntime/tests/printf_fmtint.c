// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>
#include <stdio.h>

int main() {
    int x = snrt_global_core_idx();
    int y = snrt_global_core_num();
    printf("Hello from core %i of %i\n", x, y);
    return 0;
}
