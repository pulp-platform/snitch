// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

volatile static uint32_t sum = 0;

unsigned __attribute__((noinline)) parallel_section(void) {
    unsigned tx = read_csr(minstret);
    static volatile uint32_t sum = 0;

// the following code is executed by all harts
#pragma omp parallel
    {
        tx = read_csr(minstret) - tx;
        __atomic_add_fetch(&sum, 10, __ATOMIC_RELAXED);
    }
    return sum != 8 * 10;
}

int main() {
    unsigned core_idx = snrt_cluster_core_idx();
    unsigned core_num = snrt_cluster_core_num();
    unsigned err = 0;

    // Only core 0 executes the statements below this function
    __snrt_omp_bootstrap(core_idx);

    printf("Launch overhead test\n");
    err = parallel_section();
    omp_print_prof();

    // exit
    __snrt_omp_destroy(core_idx);
    return err;
}
