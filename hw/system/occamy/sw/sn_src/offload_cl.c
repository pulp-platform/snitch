// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "device.h"
#include "offload.h"

void axpy(job_args_t* args);

typedef void (*job_func_t)(job_args_t* args);
job_func_t jobs[1] = {axpy};

void axpy(job_args_t* argv) {
    // Get args
    axpy_args_t* args = (axpy_args_t*) argv;
    double* x = (double *) (args->x_ptr);
    double* y = (double *) (args->y_ptr);
    volatile double* z = (volatile double *) (args->z_ptr);

    __rt_get_timer();

    // AXPY loop
    for (int i = 0; i < args->l; i++) {
        int offset = snrt_cluster_core_idx() * args->l + i;
        z[offset] = args->a * x[offset] + y[offset];
    }
}

volatile uint32_t *clint_mutex;
volatile __thread uint32_t *clint_p;

int main() {

    // Initialize pointers
    volatile comm_buffer_t* comm_buffer = (volatile comm_buffer_t*) get_communication_buffer();
    clint_mutex = &(comm_buffer->lock);
    clint_p = snrt_peripherals()->clint;

    // Job loop
    while (1) {
        // Reset state after wakeup
        __rt_get_timer();
        post_wakeup_cl();
        // Run job
        __rt_get_timer();
        if (snrt_is_compute_core()) {
            job_t* job = (job_t*) comm_buffer->usr_data_ptr;
            job_func_t f = jobs[job->id];
            f(&(job->argv)); // There is an event in here
            snrt_fpu_fence();
        } else {
            __rt_get_timer();
        }
        // Terminate and sleep until next job
        __rt_get_timer();
        return_hierarchical(); // There is an event in here
        __rt_get_timer();
        snrt_wfi();
    }
}
