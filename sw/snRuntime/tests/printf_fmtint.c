// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
#include <snrt.h>
#include <stdio.h>

int main() {
    int x = snrt_global_core_idx();
    int y = snrt_global_core_num();
    printf("Hello from core %i of %i\n", x, y);
    return 0;
}
