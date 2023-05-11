// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

#include "printf.h"

int main() {
    uint32_t core_global_id = snrt_global_core_idx();
    uint32_t core_global_num = snrt_global_core_num();
    uint32_t core_id = snrt_cluster_core_idx();
    uint32_t core_num = snrt_cluster_core_num();

    for (uint32_t i = 0; i < core_global_num; i++) {
        snrt_cluster_hw_barrier();
        if (i == core_global_id) {
            printf("Hello from core %i/%i\n", core_id, core_num);
        }
    }
    return 0;
}
