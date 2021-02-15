// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "matmul.h"

int main() {
    gemm_result_t result = gemm_bench(gemm_seq_ssr);
    if (snrt_global_core_idx() == 0) {
        printf("Cycles (SSR): %u\n", result.cycles_total);
        return result.errors;
    } else {
        return 0;
    }
}
