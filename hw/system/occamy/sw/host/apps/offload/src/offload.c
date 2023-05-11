// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "offload.h"

#include "host.c"

#define N_JOBS 1
#define L 24

double x[L] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
double y[L] = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
               3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3};
double z[L] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
const axpy_args_t args = {L / 8, 2, (uint64_t)x, (uint64_t)y, (uint64_t)z};
const job_t axpy = {J_AXPY, args};
job_t jobs[N_JOBS] = {axpy};

int main() {
    // Reset and ungate quadrant 0, deisolate
    reset_and_ungate_quad(0);
    deisolate_quad(0, ISO_MASK_ALL);

    // Enable interrupts to receive notice of job termination
    enable_sw_interrupts();

    // Program Snitch entry point and communication buffer
    program_snitches();

    // Wakeup Snitches for snRuntime initialization
    wakeup_snitches_cl();

    // Wait for snRuntime initialization to be over
    wait_snitches_done();

    // Send jobs
    for (int i = 0; i < N_JOBS; i++) {
        // Communicate job
        mcycle();
        comm_buffer.usr_data_ptr = (uint32_t)(uint64_t) & (jobs[i]);
        // Start Snitches
        mcycle();
        wakeup_snitches_cl();
        // Wait for job done
        mcycle();
        wait_sw_interrupt();
        // Clear interrupt
        mcycle();
        clear_sw_interrupt(0);
    }
    // Exit routine
    mcycle();
}
