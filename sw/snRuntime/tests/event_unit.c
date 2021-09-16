// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "encoding.h"
#include "eu.h"
#include "printf.h"
#include "snrt.h"

// #define tprintf(...) printf(__VA_ARGS__)
#define tprintf(...) while (0)

volatile static uint32_t sum = 0;

static void task(void *arg, uint32_t argc) {
    (void)arg;
    (void)argc;
    __atomic_add_fetch(&sum, 1, __ATOMIC_RELAXED);
    tprintf("work arg[0] = %d argc = %d\n", ((uint32_t *)arg)[0], argc);
}

int main() {
    unsigned core_idx = snrt_cluster_core_idx();
    unsigned core_num = snrt_cluster_core_num();
    unsigned err = 0;
    static unsigned arg = 0;

    // Bootstrap: Core 0 inits the event unit and all other cores enter it while
    // core 0 waits for the queue to be full of workers
    eu_init();
    if (core_idx == 0) {
        while (eu_get_workers_in_wfi() != (snrt_cluster_compute_core_num() - 1))
            ;
    } else if (snrt_is_dm_core()) {
        // Park DM core
        return 0;
    } else {
        eu_event_loop(core_idx);
        return 0;
    }

    // Dispatch a task on all harts and wait for its completion
    tprintf("-- Test 1\n");
    sum = 0;
    arg = 10;
    eu_dispatch_push(task, 1, &arg, snrt_cluster_compute_core_num());
    eu_run_empty(core_idx);
    err |= (sum != snrt_cluster_compute_core_num()) << 0;

    // Dispatch a task on 4 harts and wait for its completion
    tprintf("-- Test 2\n");
    sum = 0;
    arg = 20;
    eu_dispatch_push(task, 1, &arg, 4);
    eu_run_empty(core_idx);
    err |= (sum != 4) << 1;

    // Dispatch a task on 1 hart and wait for its completion
    tprintf("-- Test 3\n");
    sum = 0;
    arg = 30;
    eu_dispatch_push(task, 1, &arg, 1);
    eu_run_empty(core_idx);
    err |= (sum != 1) << 2;

    // exit
    eu_exit(core_idx);
    return err;
}
