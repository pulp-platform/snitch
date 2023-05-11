// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "axpy.h"
#include "data.h"
#include "snrt.h"

int main() {
    if (snrt_is_dm_core()) return 0;

    uint32_t start_cycle = mcycle();
    axpy(l, a, x, y, z);
    uint32_t end_cycle = mcycle();

    return 0;
}
