// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

volatile static uint32_t sum = 0;

static void task(void *arg, uint32_t argc) {
    uint32_t arg0 = ((uint32_t *)arg)[0];
    __atomic_add_fetch(&sum, arg0, __ATOMIC_RELAXED);
    printf("work arg[0] = %d argc = %d\n", arg0, argc);
}

uint32_t run_and_verify_task(uint32_t *arg, uint32_t n_workers) {
    eu_dispatch_push(task, 1, arg, n_workers);
    eu_run_empty(snrt_cluster_core_idx());
    return (sum != (*arg) * n_workers);
}

int main() {
    unsigned err = 0;
    static unsigned arg = 0;
    uint32_t n_workers = 0;

    // Bootstrap: Core 0 inits the event unit and all other cores enter it while
    // core 0 waits for the queue to be full of workers
    eu_init();
    if (snrt_cluster_core_idx() == 0) {
        while (eu_get_workers_in_wfi() != (snrt_cluster_compute_core_num() - 1))
            ;
    } else if (snrt_is_dm_core()) {
        // Park DM core
        return 0;
    } else {
        eu_event_loop(snrt_cluster_core_idx());
        return 0;
    }

    // Dispatch a task on all harts and wait for its completion
    printf("-- Test 1\n");
    sum = 0;
    arg = 10;
    n_workers = snrt_cluster_compute_core_num();
    err |= run_and_verify_task(&arg, n_workers) << 0;

    // Dispatch a task on 4 harts and wait for its completion
    printf("-- Test 2\n");
    sum = 0;
    arg = 20;
    n_workers = 4;
    err |= run_and_verify_task(&arg, n_workers) << 1;

    // Dispatch a task on 1 hart and wait for its completion
    printf("-- Test 3\n");
    sum = 0;
    arg = 30;
    n_workers = 1;
    err |= run_and_verify_task(&arg, n_workers) << 2;

    // exit
    eu_exit(snrt_cluster_core_idx());
    return err;
}
