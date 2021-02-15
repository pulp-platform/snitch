// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "matmul.h"

int main() {
    gemm_result_t result_baseline = gemm_bench(gemm_seq_baseline);
    if (snrt_global_core_idx() == 0) {
        printf("Cycles (Baseline): %u\n", result_baseline.cycles_total);
    }

    gemm_result_t result_ssr = gemm_bench(gemm_seq_ssr);
    if (snrt_global_core_idx() == 0) {
        printf("Cycles (SSR):      %u\n", result_ssr.cycles_total);
    }

    gemm_result_t result_ssr_frep = gemm_bench(gemm_seq_ssr_frep);
    if (snrt_global_core_idx() == 0) {
        printf("Cycles (SSR+FREP): %u\n", result_ssr_frep.cycles_total);
    }

    if (snrt_global_core_idx() == 0) {
        size_t errors =
            result_baseline.errors + result_ssr.errors + result_ssr_frep.errors;
        return errors;
    } else {
        return 0;
    }
}
