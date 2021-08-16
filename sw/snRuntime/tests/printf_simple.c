// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

#include "printf.h"

int main() {
    for (uint32_t i = 0; i < snrt_global_core_num(); i++) {
        snrt_cluster_hw_barrier();
        if (i == snrt_global_core_idx()) {
            printf("Hello, World!\n");
        }
    }
    return 0;
}
