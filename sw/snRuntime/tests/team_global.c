// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Must run with `--base-hartid=3 --num-cores=4 --num-clusters=2`
#include <snrt.h>

static const struct {
    uint32_t global_id;
    uint32_t global_num;
} table;

int main() {
    uint32_t i = snrt_hartid() - 3;  // shift by base hartid
    uint32_t errors = 0;
    errors += (snrt_global_core_idx() != i);
    errors += (snrt_global_core_num() != 8);
    errors += (snrt_cluster_idx() != i / 4);
    errors += (snrt_cluster_num() != 2);
    errors += (snrt_cluster_core_idx() != i % 4);
    errors += (snrt_cluster_core_num() != 4);
    return errors;
}
